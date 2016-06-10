/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del manejador de memoria
*/

#ifndef __MMU_H__
#define __MMU_H__

#include "../defines.h"
#include "../i386.h"

typedef struct str_pde {
    unsigned char   present:1;
    unsigned char   write:1;
    unsigned char   user:1;
    unsigned char   write_through:1;
    unsigned char   cache_disable:1;
    unsigned char   accessed:1;
    unsigned char   ignored_6:1;    // set to 0
    unsigned char   size:1;             // 0 = 4k pages
    unsigned char   global:1;
    unsigned char   ignored_9:3;
    unsigned int    base:20;
} __attribute__((__packed__, aligned (4))) pde;

typedef struct str_pte {
    unsigned char   present:1;
    unsigned char   write:1;
    unsigned char   user:1;
    unsigned char   write_through:1;
    unsigned char   cache_disable:1;
    unsigned char   accessed:1;
    unsigned char   dirty:1;
    unsigned char   attribute_index:1;
    unsigned char   global:1;
    unsigned char   ignored_9:3;
    unsigned int    base:20;
} __attribute__((__packed__, aligned (4))) pte;

#define KERNEL_PAGE_DIR ((pde*) 0x27000)
#define KERNEL_PAGE_TABLE ((pte*) 0x28000)

void mmu_inicializar();
void mmu_inicializar_dir_kernel();

void mmu_mapear_pagina_kernel(void* virtual, void* fisica);
void mmu_mapear_pagina_user(void* virtual, void* fisica, pde* dir);
void mmu_mapear_pagina(void* virtual, void* fisica, pde* dir, pte attributos);
void mmu_unmapear_pagina(void* virtual, pde* dir);

#endif	/* !__MMU_H__ */
