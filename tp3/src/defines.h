/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

    Definiciones globales del sistema.
*/

#ifndef __DEFINES_H__
#define __DEFINES_H__

#include <stdint.h>

/* Bool */
/* -------------------------------------------------------------------------- */
#define bool char
#define TRUE                    0x00000001
#define FALSE                   0x00000000
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

#define GDT_NULL_DESC            0
#define GDT_RESERVADO_1_DESC     1
#define GDT_RESERVADO_2_DESC     2
#define GDT_RESERVADO_3_DESC     3
#define GDT_CODE_0_DESC          4
#define GDT_CODE_3_DESC          5
#define GDT_DATA_0_DESC          6
#define GDT_DATA_3_DESC          7
#define GDT_VIDEO_DESC           8

/* Offsets mmu */
/* -------------------------------------------------------------------------- */
#define PAGE_DIR 0x27000
#define PAGE_SIZE 1<<12
#define INICIO_PAGINAS_LIBRES 0x100000
#define PDE_INDEX(virtual) ((virtual) >> 22)
#define PTE_INDEX(virtual) (((virtual) & 0x3ff000) >> 10)
#define PTE_BASE(dir) ((dir) & ~0xfff)
#define CR3_PD(cr3) ((cr3) & ~0xfff)
#define PTE_OFFSET(virtual) (virtual & 0xfff)
#define PG_USER 1 << 2
#define PG_READ_WRITE 1 << 1
#define PG_PRESENT 0x00000001


/* Offsets en la gdt */
/* -------------------------------------------------------------------------- */
#define GDT_OFF_NULL_DESC           (GDT_IDX_NULL_DESC      << 3)

/* Direcciones de memoria */
/* -------------------------------------------------------------------------- */
#define VIDEO_SCREEN            0x000B8000 /* direccion fisica del buffer de video */

#endif  /* !__DEFINES_H__ */
