/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del manejador de memoria
*/

#include "mmu.h"
#include "../defines.h"

void* proxima_pagina_libre;

void* celda_to_pagina(struct pos_t pos);

/**********************************
 * Funciones exportadas
 **********************************/

void mmu_inicializar() {
    proxima_pagina_libre = (void*) INICIO_PAGINAS_LIBRES;
}

void mmu_inicializar_dir_kernel(){
    // Inicializar el directorio vacío
    pde* dir = KERNEL_PAGE_DIR;
    int i;
    for(i = 0 ; i < 1024 ; i++){
        dir[i] = (pde){0};
    }

    // Inicializar los primeros 4MB con identity mapping
    pte* tabla = KERNEL_PAGE_TABLE;
    dir[0].base = PTE_BASE(tabla);
    dir[0].present = 1;
    dir[0].write = 1;

    for(i = 0; i < 1024 ; i++){
        tabla[i].base = i;
        tabla[i].present = 1;
        tabla[i].write = 1;
    }

    mmu_mapear_pagina_kernel(TAREA_IDLE,TAREA_IDLE);
    mmu_mapear_pagina_kernel(TAREA_A,TAREA_A);
    mmu_mapear_pagina_kernel(TAREA_B,TAREA_B);
    mmu_mapear_pagina_kernel(TAREA_H,TAREA_H);
}

void* mmu_proxima_pagina_fisica_libre() {
    void* pagina_libre = proxima_pagina_libre;
    proxima_pagina_libre += PAGE_SIZE;
    return pagina_libre;
}

pde* mmu_inicializar_dir_tarea(void* tarea, struct pos_t pos) {
    assert(0 <= pos.x && pos.x < 80);
    assert(0 <= pos.y && pos.y < 44);
    assert(!((int)tarea & 0xfff));
    int i;

    // Crear el directorio de paginas para la tarea e inicializarlo
    pde* dir = (pde*) mmu_proxima_pagina_fisica_libre();
    for(i = 0 ; i < 1024 ; i++){
        dir[i] = (pde){0};
    }

    // Calcular la posicion de memoria de la celda del mapa
    void* celda = celda_to_pagina(pos);

    // Mapear las paginas necesarias en el kernel para poder copiar el contenido
    mmu_mapear_pagina_kernel(celda, celda);

    // Copiar la tarea
    for(i = 0; i < 1024 ; i++) {
        *(((int*) celda) + i) = *(((int*) tarea) + i);
    }

    // Mapear la celda para la tarea
    mmu_mapear_pagina_user((void*) 0x08000000, celda, dir);

    // Mapear las paginas del kernel
    for(i = 0; i < 1024; i++){
      mmu_mapear_pagina_kernel((void*) (i * (1 << 12)), (void*) (i * (1 << 12)));
    }

    return dir;
}

void mmu_mapear_pagina_kernel(void* virtual, void* fisica){
    pte attr = {0};
    attr.present = 1;
    attr.write = 1;
    mmu_mapear_pagina(virtual, fisica, KERNEL_PAGE_DIR, attr);
}

void mmu_mapear_pagina_user(void* virtual, void* fisica, pde* dir){
    pte attr = {0};
    attr.present = 1;
    attr.write = 1;
    attr.user = 1;
    mmu_mapear_pagina(virtual, fisica, dir, attr);
}

void mmu_mapear_pagina(void* virtual, void* fisica, pde* dir, pte atributos){
    assert(!((int)virtual & 0xfff));
    assert(!((int)fisica & 0xfff));
    int i;

    pte* tabla;

    if (!dir[PDE_INDEX(virtual)].present){
        //Pseudo malloc
        tabla = (pte*) mmu_proxima_pagina_fisica_libre();

        // Inicializar las entradas de la tabla
        for (i = 0; i < 1024; i++) {
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
    atributos.base = PTE_BASE(fisica);
    atributos.present = 1;
    tabla[PTE_INDEX(virtual)] = atributos;

    // Flushear la cache
    tlbflush();
}

void mmu_unmapear_pagina(void* virtual, pde* dir){
    assert(!((int)virtual & 0xfff));

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

/**********************************
 * Cosas internas
 **********************************/

// Calcular la posicion de memoria de la celda del mapa
void* celda_to_pagina(struct pos_t pos) {
    return (void*) (BASE_MAPA + pos.x * MAP_CELL_SIZE + pos.y * 80 * MAP_CELL_SIZE);
}
