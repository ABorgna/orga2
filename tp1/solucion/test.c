#include "tdt.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

void printmaxmin(FILE *pFile, tdt* tabla);

int main (void){
    uint8_t clave0[3] = {0,0,0};
    uint8_t valor0[15] = {0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
                          0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF};
    uint8_t clave1[3] = {0xFF,0xFF,0xFF};
    uint8_t valor1[15] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

    bloque b0 = {{5,5,5},{0x12,0x34,0x56,0x78,0x9A,0xBC,0xDE,0xF1,
                          0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF}};
    bloque b1 = {{0xFF,0xFF,0xFF},{0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,
                                   0x99,0xAA,0xBB,0xCC,0xDD,0xEE,0xFF}};
    bloque b2 = {{0x53,0xFF,0xAA},{0x11,0x12,0x22,0x33,0x34,0x44,0x55,0x56,
                                   0x66,0x77,0x78,0x88,0x99,0x9A,0xAA}};
    bloque b3 = {{0x10,0xEE,0x05},{0x11,0x11,0x22,0x22,0x33,0x33,0x44,0x44,
                                   0x55,0x55,0x66,0x66,0x77,0x77,0x88}};
    bloque* bb[5] = {&b0,&b1,&b2,&b3,0};

    // 1
    tdt* tabla = tdt_crear("pepe");

    // 2
    tdt_agregar(tabla,clave0,valor0);
    tdt_agregar(tabla,clave1,valor1);

    // 3
    tdt_agregarBloques(tabla,bb);

    // 4
    tdt_borrarBloque(tabla,&b2);
    tdt_borrarBloque(tabla,&b1);

    // 5
    printmaxmin(stdout, tabla);

    // 6
    tdt_imprimirTraducciones(tabla,stdout);

    // 7
    fprintf(stdout, "Cantidad: %d\n",tdt_cantidad(tabla));

    // 8
    tdt_destruir(&(tabla));

    return 0;
}

void printmaxmin(FILE *pFile, tdt* tabla) {
    int i;
    maxmin *mm = tdt_obtenerMaxMin(tabla);

    fprintf(pFile,"max_clave => ");
    for(i=0;i<3;i++) fprintf(pFile,"%02X",mm->max_clave[i]);
    fprintf(pFile,"\n");

    fprintf(pFile,"min_clave => ");
    for(i=0;i<3;i++) fprintf(pFile,"%02X",mm->min_clave[i]);
    fprintf(pFile,"\n");

    fprintf(pFile,"max_valor => ");
    for(i=0;i<15;i++) fprintf(pFile,"%02X",mm->max_valor[i]);
    fprintf(pFile,"\n");

    fprintf(pFile,"min_valor => ");
    for(i=0;i<15;i++) fprintf(pFile,"%02X",mm->min_valor[i]);
    fprintf(pFile,"\n");
    free(mm);
}
