#include "tdt.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main (void){
    tdt* tabla = tdt_crear("pepe");
    uint16_t i,j,k,l;
    uint8_t clave[3];
    uint8_t valor[15];

    srand(0xDEADBEEF);

    for(k=0; k<256; k++) {
        clave[0] = k;
        for(j=0; j<256; j++) {
            clave[1] = j;
            for(i=0; i<256; i++) {
                clave[2] = i;
                for(l=0; l<15; l++) {
                    valor[l] = rand();
                }
                tdt_agregar(tabla,valor,clave);
            }
        }
    }

    tdt_destruir(&tabla);

    return 0;
}

