/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de estructuras para administrar tareas
*/

#include "tss.h"
#include "../mem/mmu.h"

tss tss_inicial;
tss tss_idle;
tss tss_H[15];
tss tss_A[5];
tss tss_B[5];

void tss_idle_inicializar() {
    int estac_ptr = sp();
    unsigned int beis_ptr = bp();
    tss_idle = (tss) {
        (unsigned short)   0,               /* ptl;       */
        (unsigned short)   0,               /* unused0;   */
        (unsigned int)     estac_ptr,       /* esp0;      */
        (unsigned short)   GDT_DATA_0_DESC, /* ss0;       */
        (unsigned short)   0,               /* unused1;   */
        (unsigned int)     0,               /* esp1;      */
        (unsigned short)   0,               /* ss1;       */
        (unsigned short)   0,               /* unused2;   */
        (unsigned int)     0,               /* esp2;      */
        (unsigned short)   0,               /* ss2;       */
        (unsigned short)   0,               /* unused3;   */
        (unsigned int)     KERNEL_PAGE_DIR, /* cr3;       */
        (unsigned int)     TAREA_IDLE,      /* eip;       */
        (unsigned int)     0x202,           /* eflags;    */
        (unsigned int)     0,               /* eax;       */
        (unsigned int)     0,               /* ecx;       */
        (unsigned int)     0,               /* edx;       */
        (unsigned int)     0,               /* ebx;       */
        (unsigned int)     estac_ptr,       /* esp;       */
        (unsigned int)     beis_ptr,        /* ebp;       */
        (unsigned int)     0,               /* esi;       */
        (unsigned int)     0,               /* edi;       */
        (unsigned short)   GDT_DATA_0_DESC, /* es;        */
        (unsigned short)   0,               /* unused4;   */
        (unsigned short)   GDT_CODE_0_DESC, /* cs;        */
        (unsigned short)   0,               /* unused5;   */
        (unsigned short)   GDT_DATA_0_DESC, /* ss;        */
        (unsigned short)   0,               /* unused6;   */
        (unsigned short)   GDT_DATA_0_DESC, /* ds;        */
        (unsigned short)   0,               /* unused7;   */
        (unsigned short)   GDT_VIDEO_0_DESC,/* fs;        */
        (unsigned short)   0,               /* unused8;   */
        (unsigned short)   GDT_DATA_0_DESC, /* gs;        */
        (unsigned short)   0,               /* unused9;   */
        (unsigned short)   0,               /* ldt;       */
        (unsigned short)   0,               /* unused10;  */
        (unsigned short)   0,               /* dtrap;     */
        (unsigned short)   0,               /* iomap;     */
    };
}

void tss_inicializar_tarea(tss* entrada, pde* cr3) {
    void* pagina_stack_kernel = mmu_proxima_pagina_fisica_libre();
    void* stack_kernel = pagina_stack_kernel + 0x1000 - 4;

    *entrada = (tss) {
        (unsigned short)   0,               /* ptl;       */
        (unsigned short)   0,               /* unused0;   */
        (unsigned int)     stack_kernel,    /* esp0;      */
        (unsigned short)   GDT_DATA_0_DESC, /* ss0;       */
        (unsigned short)   0,               /* unused1;   */
        (unsigned int)     0,               /* esp1;      */
        (unsigned short)   0,               /* ss1;       */
        (unsigned short)   0,               /* unused2;   */
        (unsigned int)     0,               /* esp2;      */
        (unsigned short)   0,               /* ss2;       */
        (unsigned short)   0,               /* unused3;   */
        (unsigned int)     cr3,             /* cr3;       */
        (unsigned int)     TAREA_PAGINA_0,  /* eip;       */
        (unsigned int)     0x202,           /* eflags;    */
        (unsigned int)     0,               /* eax;       */
        (unsigned int)     0,               /* ecx;       */
        (unsigned int)     0,               /* edx;       */
        (unsigned int)     0,               /* ebx;       */
        (unsigned int)     TAREA_PAGINA_1-4,/* esp;       */
        (unsigned int)     TAREA_PAGINA_1-4,/* ebp;       */
        (unsigned int)     0,               /* esi;       */
        (unsigned int)     0,               /* edi;       */
        (unsigned short)   GDT_DATA_3_DESC, /* es;        */
        (unsigned short)   0,               /* unused4;   */
        (unsigned short)   GDT_CODE_3_DESC, /* cs;        */
        (unsigned short)   0,               /* unused5;   */
        (unsigned short)   GDT_DATA_3_DESC, /* ss;        */
        (unsigned short)   0,               /* unused6;   */
        (unsigned short)   GDT_DATA_3_DESC, /* ds;        */
        (unsigned short)   0,               /* unused7;   */
        (unsigned short)   GDT_VIDEO_3_DESC,/* fs;        */
        (unsigned short)   0,               /* unused8;   */
        (unsigned short)   GDT_DATA_3_DESC, /* gs;        */
        (unsigned short)   0,               /* unused9;   */
        (unsigned short)   0,               /* ldt;       */
        (unsigned short)   0,               /* unused10;  */
        (unsigned short)   0,               /* dtrap;     */
        (unsigned short)   0,               /* iomap;     */
    };
}
