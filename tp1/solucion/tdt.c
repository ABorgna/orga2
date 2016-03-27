#include "tdt.h"

void tdt_agregar(tdt* tabla, uint8_t* clave, uint8_t* valor) {
    tdtN1 *t1;
    tdtN2 *t2;
    tdtN3 *t3;

    if(!tabla->primera) {
        tabla->primera = (tdtN1*) calloc(1,sizeof(tdtN1));
    }
    t1 = tabla->primera;

    if(!t1->entradas[clave[0]]) {
        t1->entradas[clave[0]] = (tdtN2*) calloc(1,sizeof(tdtN2));
    }
    t2 = t1->entradas[clave[0]];

    if(!t2->entradas[clave[1]]) {
        t2->entradas[clave[1]] = (tdtN3*) calloc(1,sizeof(tdtN3));
    }
    t3 = t2->entradas[clave[1]];

    if(!t3->entradas[clave[2]].valido) {
        tabla->cantidad++;
        t3->entradas[clave[2]].valido = 1;
    }

    memcpy(&(t3->entradas[clave[2]]),valor,15);
}

void tdt_borrar(tdt* tabla, uint8_t* clave) {
    tdtN1 *t1;
    tdtN2 *t2;
    tdtN3 *t3;
    uint64_t anyValid, i;

    if(!(t1 = tabla->primera)) return;
    if(!(t2 = t1->entradas[clave[0]])) return;
    if(!(t3 = t2->entradas[clave[1]])) return;

    if(t3->entradas[clave[2]].valido) {
        tabla->cantidad--;
        t3->entradas[clave[2]].valido = 0;
    }

    for(i=0, anyValid = 0; i < 256; i++) anyValid |= t3->entradas[i].valido;
    if(!anyValid) {
        free(t3);
        t2->entradas[clave[1]] = 0;
    } else return;

    for(i=0, anyValid = 0; i < 256; i++) anyValid |= (uint64_t) t2->entradas[i];
    if(!anyValid) {
        free(t2);
        t1->entradas[clave[0]] = 0;
    } else return;

    for(i=0, anyValid = 0; i < 256; i++) anyValid |= (uint64_t) t1->entradas[i];
    if(!anyValid) {
        free(t1);
        tabla->primera = 0;
    } else return;
}

void tdt_imprimirTraducciones(tdt* tabla, FILE *pFile) {
    tdtN1 *t1;
    tdtN2 *t2;
    tdtN3 *t3;
    valorValido val;
    uint16_t i,j,k,c;

    fprintf(pFile, "- %s -\n", tabla->identificacion);
    if(!(t1 = tabla->primera)) return;

    for(k=0; k<256; k++) {
        if(!(t2 = t1->entradas[k])) continue;

        for(j=0; j<256; j++) {
            if(!(t3 = t2->entradas[j])) continue;

            for(i=0; i<256; i++) {
                val = t3->entradas[i];
                if(!val.valido) continue;

                fprintf(pFile, "%02X%02X%02X => ", k,j,i);
                for(c=0; c < 15; c++) {
                    fprintf(pFile, "%02X", val.valor.val[c]);
                }
                fprintf(pFile, "\n");
            }
        }
    }
}

maxmin* tdt_obtenerMaxMin(tdt* tabla) {
    maxmin *mm = (maxmin*) calloc(1,sizeof(maxmin));
    tdtN1 *t1;
    tdtN2 *t2;
    tdtN3 *t3;
    valorValido val;
    uint16_t i,j,k,c;
    uint8_t first = 1, isGt,isL;

    memset(&(mm->min_valor),0xff,15);
    memset(&(mm->min_clave),0xff,3);

    if(!(t1 = tabla->primera)) return mm;

    for(k=0; k<256; k++) {
        if(!(t2 = t1->entradas[k])) continue;

        for(j=0; j<256; j++) {
            if(!(t3 = t2->entradas[j])) continue;

            for(i=0; i<256; i++) {
                val = t3->entradas[i];
                if(!val.valido) continue;

                if(first) {
                    isL = 1;
                    isGt = 1;
                    mm->min_clave[0] = k;
                    mm->min_clave[1] = j;
                    mm->min_clave[2] = i;
                    first = 0;
                } else {
                    isL = 0;
                    isGt = 0;
                    for(c=0; c < 15; c++) {
                        if(val.valor.val[c] < mm->min_valor[c]) {
                            isL = 1;
                            break;
                        } else if (val.valor.val[c] > mm->min_valor[c]) {
                       break;
                        }
                    }
                    for(c=0; c < 15; c++) {
                        if(val.valor.val[c] > mm->max_valor[c]) {
                            isGt = 1;
                            break;
                        } else if(val.valor.val[c] < mm->max_valor[c]) {
                            break;
                        }
                    }
                }

                if(isL) {
                    memcpy(mm->min_valor,&val,15);
                }
                if(isGt) {
                    memcpy(mm->max_valor,&val,15);
                }
                mm->max_clave[0] = k;
                mm->max_clave[1] = j;
                mm->max_clave[2] = i;
            }
        }
    }
    return mm;
}

