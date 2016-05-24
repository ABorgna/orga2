/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del manejador de memoria
*/

#include "mmu.h"

void mmu_inicializar() {
	
}

void mmu_inicializar_dir_kernel(){
	int *dir = (int*) 0x27000;
	int i;
	for(i = 0 ; i < 1024 ; i++){
		dir[i] = 0;
	}
	dir[0] = 0x28000 | 0x3;
	int * tab = (int*) 0x28000;
	for(i = 0; i < 1024 ; i++){
		tab[i] = 0x1000*i | 0x03;
	}
}





