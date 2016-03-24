#include "tdt.h"

// Convertir de puntero generico a las parte alta o baja de un numero de 128b
#define HIGH_64(x) *((uint64_t*)(x)+8)
#define LOW_64(x) *((uint64_t*)(x))

void tdt_agregar(tdt* tabla, uint8_t* clave, uint8_t* valor) {
    tdtN1 *t1;
    tdtN2 *t2;
    tdtN3 *t3;

    if(!tabla->primera) {
        tabla->primera = (tdtN1*) malloc(sizeof(tdtN1));
    }
    t1 = tabla->primera;

    if(!t1->entradas[clave[0]]) {
        t1->entradas[clave[0]] = (tdtN2*) malloc(sizeof(tdtN2));
    }
    t2 = t1->entradas[clave[0]];

    if(!t2->entradas[clave[1]]) {
        t2->entradas[clave[1]] = (tdtN3*) malloc(sizeof(tdtN3));
    }
    t3 = t2->entradas[clave[1]];

    memcpy(&(t3->entradas[clave[2]]),valor,15);
    t3->entradas[clave[2]].valido = 1;
    tabla->cantidad++;
}

void tdt_borrar(tdt* tabla, uint8_t* clave) {
    tdtN1 *t1;
    tdtN2 *t2;
    tdtN3 *t3;
    uint64_t anyValid, i;

    if(!(t1 = tabla->primera)) return;
    if(!(t2 = t1->entradas[clave[0]])) return;
    if(!(t3 = t2->entradas[clave[1]])) return;
    t3->entradas[clave[2]].valido = 0;
    tabla->cantidad--;

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
    uint16_t i,j,k;

    fprintf(pFile, "- %s -\n", tabla->identificacion);
    if(!(t1 = tabla->primera)) return;

    for(k=0; k<256; k++) {
        if(!(t2 = t1->entradas[k])) continue;

        for(j=0; j<256; j++) {
            if(!(t3 = t2->entradas[j])) continue;

            for(i=0; i<256; i++) {
                val = t3->entradas[i];
                if(!val.valido) continue;
                val.valido = 0;

                fprintf(pFile, "%2X%2X%2X => ", k,j,i);
                fprintf(pFile, "%14lX", HIGH_64(&val));
                fprintf(pFile, "%16lX", LOW_64(&val));
                fprintf(pFile, "\n");

                val.valido = 1;
            }
        }
    }
}

maxmin* tdt_obtenerMaxMin(tdt* tabla) {
    maxmin *mm = (maxmin*) calloc(1,sizeof(maxmin*));
    tdtN1 *t1;
    tdtN2 *t2;
    tdtN3 *t3;
    valorValido val;
    uint16_t i,j,k;
    uint8_t first = 1;

    if(!(t1 = tabla->primera)) return mm;

    for(k=0; k<256; k++) {
        if(!(t2 = t1->entradas[k])) continue;

        for(j=0; j<256; j++) {
            if(!(t3 = t2->entradas[j])) continue;

            for(i=0; i<256; i++) {
                val = t3->entradas[i];
                if(!val.valido) continue;
                val.valido = 0;

                if(first || HIGH_64(&val) > HIGH_64(mm->max_valor) ||
                    (HIGH_64(&val) == HIGH_64(mm->max_valor) &&
                     LOW_64(&val) > LOW_64(mm->max_valor))) {
                    mm->max_clave[2] = k;
                    mm->max_clave[1] = j;
                    mm->max_clave[0] = i;
                    memcpy(mm->max_valor,&val,15);
                }

                if(first || HIGH_64(&val) < HIGH_64(mm->min_valor) ||
                    (HIGH_64(&val) == HIGH_64(mm->min_valor) &&
                     LOW_64(&val) < LOW_64(mm->min_valor))) {
                    mm->min_clave[2] = k;
                    mm->min_clave[1] = j;
                    mm->min_clave[0] = i;
                    memcpy(mm->min_valor,&val,15);
                }

                val.valido = 1;
                first = 0;
            }
        }
    }

    return mm;
}

