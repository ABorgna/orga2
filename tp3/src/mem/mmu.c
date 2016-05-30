/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del manejador de memoria
*/

#include "mmu.h"

unsigned int proxima_pagina_libre;

void mmu_inicializar() {
    proxima_pagina_libre = INICIO_PAGINAS_LIBRES;
}

void mmu_inicializar_dir_kernel(){
    // Inicializar el directorio vacío
    pde* dir = KERNEL_PAGE_DIR;
    for(int i = 0 ; i < 1024 ; i++){
        dir[i] = (pde){0};
    }

    // Inicializar los primeros 4MB con identity mapping
    pte* tabla = KERNEL_PAGE_TABLE;
    dir[0].base = PTE_BASE(tabla);
    dir[0].present = 1;
    dir[0].write = 1;

    for(int i = 0; i < 1024 ; i++){
        tabla[i].base = i;
        tabla[i].present = 1;
        tabla[i].write = 1;
    }
}

unsigned int mmu_proxima_pagina_fisica_libre() {
    unsigned int pagina_libre = proxima_pagina_libre;
    proxima_pagina_libre += PAGE_SIZE;
    return pagina_libre;
}

void mmu_inicializar_dir_tarea() {
    /* todo */
}

void mmu_mapear_pagina_kernel(unsigned int virtual, unsigned int cr3, unsigned int fisica){
    pte attr = {0};
    attr.present = 1;
    attr.write = 1;
    mmu_mapear_pagina(virtual, cr3, fisica, attr);
}

void mmu_mapear_pagina_user(unsigned int virtual, unsigned int cr3, unsigned int fisica){
    pte attr = {0};
    attr.present = 1;
    attr.write = 1;
    attr.user = 1;
    mmu_mapear_pagina(virtual, cr3, fisica, attr);
}

void mmu_mapear_pagina(unsigned int virtual, unsigned int cr3, unsigned int fisica, pte attributos){
    pde* dir = (pde*) CR3_PD(cr3);
    pte* tabla;

    if (!dir[PDE_INDEX(virtual)].present){
        //Pseudo malloc
        tabla = (pte*) mmu_proxima_pagina_fisica_libre();

        // Inicializar las entradas de la tabla
        for (int i = 0; i < 1024; i++) {
            tabla[i] = (pte){0};
        }

        // Agregar la nueva tabla al directorio
        dir[PDE_INDEX(virtual)].base = PTE_BASE(tabla);
        dir[PDE_INDEX(virtual)].present = 1;
        dir[PDE_INDEX(virtual)].write = 1;
    }
    else {
        tabla = (pte*) PTE_BASE_TO_PTR(dir[PDE_INDEX(virtual)].base);
    }

    // Mapeamos su página en la tabla
    tabla[PTE_INDEX(virtual)].base = PTE_BASE(fisica);
    tabla[PTE_INDEX(virtual)].present = 1;
    tabla[PTE_INDEX(virtual)].write = 1;

    // Flushear la cache
    tlbflush();
}

void mmu_unmapear_pagina(unsigned int virtual, unsigned int cr3){
    pde* dir = (pde*) CR3_PD(cr3);
    pte* tabla;

    // No hacemos nada si la tabla no estaba mapeada
    if(!dir[PDE_INDEX(virtual)].present) {
        return;
    }

    tabla = (pte*) PTE_BASE_TO_PTR(dir[PDE_INDEX(virtual)].base);

    // Tampoco hacer nada si la pagina no estaba mapeada en la tabla
    if(!tabla[PTE_INDEX(virtual)].present){
        return;
    }

    tabla[PTE_INDEX(virtual)].present = 0;

    // Flushear la cache
    tlbflush();
}
