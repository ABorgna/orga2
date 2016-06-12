/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#ifndef __GAME_H__
#define __GAME_H__

#include "defines.h"

typedef enum direccion_e { IZQ = 0xAAA, DER = 0x441, ARB = 0xA33, ABA = 0x883  } direccion;

// Lets play a game
void game_inicializar();

// Interaccion con el jugador
void game_mover_cursor(player_group player, direccion dir);
void game_lanzar(player_group player, struct pos_t pos);

// Actualizar, cambiar de tarea y todo eso
// Se llama con el RTC cada 1ms
void game_tick();

// Syscalls
void game_soy(unsigned int soy);
void game_donde(struct pos_t* pos);
void game_mapear(unsigned int x, unsigned int y);

// Otros
void game_kill_task();

#endif  /* !__GAME_H__ */
