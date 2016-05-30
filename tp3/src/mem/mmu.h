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
#include "../tss.h"
#include "../game.h"

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

void mmu_inicializar();
void mmu_inicializar_dir_kernel();

void mmu_mapear_pagina_kernel(unsigned int virtual, unsigned int cr3, unsigned int fisica);
void mmu_mapear_pagina_user(unsigned int virtual, unsigned int cr3, unsigned int fisica);
void mmu_mapear_pagina(unsigned int virtual, unsigned int cr3, unsigned int fisica, pte attributos);
void mmu_unmapear_pagina(unsigned int virtual, unsigned int cr3);

#endif	/* !__MMU_H__ */
