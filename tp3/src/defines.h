/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

    Definiciones globales del sistema.
*/

#ifndef __DEFINES_H__
#define __DEFINES_H__

#include <stdint.h>

/* Assertions */
/* -------------------------------------------------------------------------- */
#define assert(x) {if(!(x)){__asm __volatile("xchg %%bx, %%bx" : :);}}


/* Bool */
/* -------------------------------------------------------------------------- */
#define bool char
#define TRUE                    0x00000001
#define FALSE                   0x00000000
#define true                    0x00000001
#define false                   0x00000000
#define ERROR                   1


/* Misc */
/* -------------------------------------------------------------------------- */
#define CANT_H                 15
#define CANT                    5
#define SIZE_W                  80
#define SIZE_H                  44


/* Indices en la gdt */
/* -------------------------------------------------------------------------- */
#define GDT_COUNT 9

#define GDT_NULL_INDEX           0
#define GDT_RESERVADO_1_INDEX    1
#define GDT_RESERVADO_2_INDEX    2
#define GDT_RESERVADO_3_INDEX    3
#define GDT_CODE_0_INDEX         4
#define GDT_CODE_3_INDEX         5
#define GDT_DATA_0_INDEX         6
#define GDT_DATA_3_INDEX         7
#define GDT_VIDEO_INDEX          8

#define GDT_NULL_DESC            0 << 3
#define GDT_RESERVADO_1_DESC     1 << 3
#define GDT_RESERVADO_2_DESC     2 << 3
#define GDT_RESERVADO_3_DESC     3 << 3
#define GDT_CODE_0_DESC          4 << 3
#define GDT_CODE_3_DESC          5 << 3
#define GDT_DATA_0_DESC          6 << 3
#define GDT_DATA_3_DESC          7 << 3
#define GDT_VIDEO_DESC           8 << 3

/* MMU */
/* -------------------------------------------------------------------------- */
#define PAGE_SIZE (1<<12)
#define INICIO_PAGINAS_LIBRES 0x100000
#define PDE_INDEX(virtual) ((unsigned int)(virtual) >> 22)
#define PTE_INDEX(virtual) (((unsigned int)(virtual) & 0x3ff000) >> 10)
#define PTE_BASE(dir) ((unsigned int)(dir) >> 12)
#define PTE_BASE_TO_PTR(dir) ((void*)((unsigned int)(dir) << 12))
#define CR3_PD(cr3) ((cr3) & ~0xfff)
#define PTE_OFFSET(virtual) ((unsigned int)(virtual) & 0xfff)


/* Mapa y tareas */
/* -------------------------------------------------------------------------- */
#define MAP_CELL_SIZE 0x1000
#define BASE_MAPA ((void*) 0x400000)
#define TAREA_IDLE ((void*) 0x10000)
#define TAREA_A ((void*) 0x11000)
#define TAREA_B ((void*) 0x12000)
#define TAREA_H ((void*) 0x13000)


/* Offsets en la gdt */
/* -------------------------------------------------------------------------- */
#define GDT_OFF_NULL_DESC           (GDT_IDX_NULL_DESC      << 3)

/* Direcciones de memoria */
/* -------------------------------------------------------------------------- */
#define VIDEO_SCREEN            0x000B8000 /* direccion fisica del buffer de video */

/* Macros utiles */
/* -------------------------------------------------------------------------- */
#define ARRAY_SIZE(foo) (sizeof(foo)/sizeof(foo[0]))

#endif  /* !__DEFINES_H__ */
