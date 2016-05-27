/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del manejador de memoria
*/

#include "mmu.h"
#define PAGE_SIZE 1<<12
#define INICIO_PAGINAS_LIBRES 0x100000

unsigned int proxima_pagina_libre;

void mmu_inicializar() {
	proxima_pagina_libre = INICIO_PAGINAS_LIBRES;
}

void mmu_inicializar_dir_kernel(){
	int *dir = (int*) PAGE_DIR;
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

unsigned int mmu_proxima_pagina_fisica_libre() {
	unsigned int pagina_libre = proxima_pagina_libre;
	proxima_pagina_libre += PAGE_SIZE;
	return pagina_libre;
}

void mmu_mapear_pagina(unsigned int virtual, unsigned int cr3, unsigned int fisica /* agregar atributos a futuro*/ ){
/* considerar pasar por parámetro también los atributos de los descriptores*/
	int *dir = (int*) CR3_PD(cr3);
	int *tab;
	int i, nueva_pag;

	if (! (dir[PDE_INDEX(virtual)] & PG_PRESENT)){
		nueva_pag = mmu_proxima_pagina_fisica_libre();					//Pseudo malloc
		tab = (int*) nueva_pag;
		dir[PDE_INDEX(virtual)] = nueva_pag | 0x3;							//Indexamos @ PDE y luego cereamos la nueva tabla

		for (i = 0; i < 1024; i++) {
			tab[i] = 0;
		}

	}
	else {
		tab = (int*) PTE_BASE(dir[PDE_INDEX(virtual)]);
	}

	tab[PTE_INDEX(virtual)] = PTE_BASE(fisica) | 0x3;		//Mapeamos su página a una posición múltiplo de PAGE_SIZE
	tlbflush();
}

void mmu_unmapear_pagina(unsigned int virtual, unsigned int cr3){
	int *dir = (int*) CR3_PD(cr3);
	int *tab;
	int i;

/* análogo a mapear, pero se quita el flag de presenta para las tablas que quedan vacías*/
/* se asume que el parámetro de la dirección virtual ya se encuentra mapeado */

	tab = (int*) PTE_BASE(dir[PDE_INDEX(virtual)]);
	tab[PTE_INDEX(virtual)] = 0;
	int tabla_vacia = TRUE;

	for (i = 0; i < 1024 && tabla_vacia; i++) {
		if (tab[i] & PG_PRESENT) tabla_vacia = FALSE;
	}

	if (tabla_vacia){
		dir[PDE_INDEX(virtual)] = 0;
	}
	tlbflush();
}
