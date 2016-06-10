/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#ifndef __SCHED_H__
#define __SCHED_H__

#include "defines.h"

typedef enum{
    sched_H = 0,
    sched_A = 1,
    sched_B = 2,
    sched_Idle = 0xff
} sched_group;

void sched_inicializar();

// Devuelve el offset del nuevo tss_entry,
// 0 si no hay que cambiar
short sched_proxima_tarea();

// Devuelve el indice de la nueva tarea,
// -1 si no puede hacer un carajo
char sched_run_task(sched_group tipo);

// kill -9
void sched_kill_task(sched_group tipo, char index);

// Set current task to Idle
void sched_idle();

#endif  /* !__SCHED_H__ */
