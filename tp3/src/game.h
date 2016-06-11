/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#ifndef __GAME_H__
#define __GAME_H__

#include "defines.h"

typedef enum direccion_e { IZQ = 0xAAA, DER = 0x441, ARB = 0xA33, ABA = 0x883  } direccion;

// Interaccion con el jugador
void game_lanzar(unsigned int jugador);
void game_mover_cursor(int jugador, direccion dir);

// Actualizar, cambiar de tarea y todo eso
// Se llama con el RTC cada 1ms
void game_tick();

// Syscalls
void game_soy(unsigned int soy);
void game_donde(unsigned int* pos);
void game_mapear(int x, int y);

// Otros
void game_kill_task();

#endif  /* !__GAME_H__ */
