/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#ifndef __GAME_H__
#define __GAME_H__

#include "defines.h"
#include "tasks/tss.h"
#include "mem/mmu.h"

typedef enum direccion_e { IZQ = 0xAAA, DER = 0x441, ARB = 0xA33, ABA = 0x883  } direccion;

struct task_state {
    // Seteadas al inicializar el juego
    tss* tss;
    short tss_desc;

    // Cosas de la tarea
    bool alive;
    struct pos_t pos;
    player_group original_group;
    player_group curr_group;
    pde* cr3;

    // Paginas mapeadas
    bool has_mapped;
    struct pos_t mapped_pos;
};

// Lets play a game
void game_inicializar();

// Restart
void game_show_restart_msg();
void game_hide_restart_msg();
bool game_restart_msg_shown();
void game_restart();

// Interaccion con el jugador
void game_mover_cursor(player_group player, direccion dir);
void game_lanzar_inplace(player_group player);
void game_lanzar(player_group player, struct pos_t pos);

// Actualizar, cambiar de tarea y todo eso
// Se llama con el RTC cada 1ms
void game_tick();
void game_update_clocks(struct task_state** game_entries, char* game_max_entries, char** clocks);

// Syscalls
void game_soy(unsigned int soy);
void game_donde(struct pos_t* pos);
void game_mapear(unsigned int x, unsigned int y);

// Debugger
bool dbg_enabled;
bool dbg_displayed;
void game_show_debug();
void game_hide_debug();

// Otros
void game_kill_task();

#endif  /* !__GAME_H__ */
