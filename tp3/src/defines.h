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
#define GDT_COUNT 37

#define GDT_NULL_INDEX           0
#define GDT_RESERVADO_1_INDEX    1
#define GDT_RESERVADO_2_INDEX    2
#define GDT_RESERVADO_3_INDEX    3
#define GDT_CODE_0_INDEX         4
#define GDT_CODE_3_INDEX         5
#define GDT_DATA_0_INDEX         6
#define GDT_DATA_3_INDEX         7
#define GDT_VIDEO_0_INDEX        8
#define GDT_VIDEO_3_INDEX        9
#define GDT_TSS_IDLE             10
#define GDT_TSS_HS               11
#define GDT_TSS_AS               26
#define GDT_TSS_BS               31
#define GDT_TSS_INICIAL          36

#define GDT_NULL_DESC            (0 << 3)
#define GDT_RESERVADO_1_DESC     (1 << 3)
#define GDT_RESERVADO_2_DESC     (2 << 3)
#define GDT_RESERVADO_3_DESC     (3 << 3)
#define GDT_CODE_0_DESC          (4 << 3)
#define GDT_CODE_3_DESC         ((5 << 3) | 0x3)
#define GDT_DATA_0_DESC          (6 << 3)
#define GDT_DATA_3_DESC         ((7 << 3) | 0x3)
#define GDT_VIDEO_0_DESC         (8 << 3)
#define GDT_VIDEO_3_DESC        ((9 << 3) | 0x3)
#define GDT_TSS_IDLE_DESC        (10 << 3)
#define GDT_TSS_HS_DESC          (11<< 3)
#define GDT_TSS_AS_DESC          (26<< 3)
#define GDT_TSS_BS_DESC          (31<< 3)
#define GDT_TSS_INICIAL_DESC     (35<< 3)

/* MMU */
/* -------------------------------------------------------------------------- */
#define PAGE_SIZE (1<<12)
#define INICIO_PAGINAS_LIBRES 0x100000
#define PDE_INDEX(virtual) ((unsigned int)(virtual) >> 22)
#define PTE_INDEX(virtual) (((unsigned int)(virtual) & 0x3ff000) >> 12)
#define PTE_BASE(dir) ((unsigned int)(dir) >> 12)
#define PTE_BASE_TO_PTR(dir) ((void*)((unsigned int)(dir) << 12))
#define CR3_PD(cr3) ((cr3) & ~0xfff)
#define PTE_OFFSET(virtual) ((unsigned int)(virtual) & 0xfff)
#define TO_PAGINA(ptr) ((void*) ((unsigned int)(ptr) & ~0xfff))


/* Mapa y tareas */
/* -------------------------------------------------------------------------- */
#define MAP_CELL_SIZE 0x1000
#define BASE_MAPA ((void*) 0x400000)
#define TAREA_IDLE ((void*) 0x10000)
#define TAREA_A ((void*) 0x11000)
#define TAREA_B ((void*) 0x12000)
#define TAREA_H ((void*) 0x13000)
#define SOY_A 0x841
#define SOY_B 0x325
#define TAREA_PAGINA_0 ((void*)0x08000000)
#define TAREA_PAGINA_1 ((void*)0x08001000)
#define MAPA_BORDE_IZQ 0
#define MAPA_BORDE_ARB 5
#define MAPA_BORDE_DER 79
#define MAPA_BORDE_ABA 48

typedef enum{
    player_H = 0,
    player_A = 1,
    player_B = 2,
    player_idle = 0xff
} player_group;

struct pos_t {
    short x;
    short y;
} pos_xy;

/* Base de descriptores en la gdt */
/* -------------------------------------------------------------------------- */
#define BASE1(dir)  (((unsigned int) (dir)) & 0xffff)
#define BASE2(dir)  (((unsigned int) (dir)) & 0x3f0000)
#define BASE3(dir)  (((unsigned int) (dir)) & 0xffc00000)

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
