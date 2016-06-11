/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#ifndef __SCHED_H__
#define __SCHED_H__

#include "../defines.h"

void sched_inicializar();

// Devuelve el offset del nuevo tss_entry,
// 0 si no hay que cambiar
void sched_proxima_tarea(player_group *group, char *index);

// Marcar una tarea como lista para correr
void sched_run_task(player_group tipo, char index);

// kill -9
void sched_kill_task(player_group tipo, char index);

#endif  /* !__SCHED_H__ */
