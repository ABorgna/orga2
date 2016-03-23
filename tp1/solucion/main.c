#include "tdt.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main (void){

    tdt* tabla = tdt_crear("sa");
    
    tdt_destruir(&(tabla));
    
    return 0;    
}
