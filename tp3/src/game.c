/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#include "game.h"

#include "defines.h"
#include "screen.h"
#include "mem/mmu.h"
#include "tasks/sched.h"
#include "tasks/tss.h"

struct task_state {
    player_group original_group;
    char sched_entry;

    player_group curr_group;

    bool alive;
    struct pos_t pos;

    void* cr3;

    // Paginas mapeadas
    bool has_mapped;
    struct pos_t mapped_pos;

};

struct pos_t players_pos[2];

player_group current_group;
char current_index;
struct task_state game_entries[3][15];
char game_max_entries[3] = {15,5,5};

/**********************************
 * Interaccion con el jugador
 **********************************/

void game_mover_cursor(int jugador, direccion dir) {
}

void game_lanzar(unsigned int jugador) {
}

/**********************************
 * Actualizar, cambiar de tarea y todo eso
 * Se llama con el RTC cada 1ms
 **********************************/
void game_tick() {
}

/**********************************
 * Syscalls
 **********************************/

void game_soy(unsigned int yoSoy) {
    if(current_group == player_idle) return;

 	if(yoSoy == 0x841)
    	game_entries[current_group][current_index].curr_group = player_A;
    else if (yoSoy == 0x325)
    	game_entries[current_group][current_index].curr_group = player_B;
    else
    	game_entries[current_group][current_index].curr_group = player_H;

    sched_idle();
    current_group = player_idle;
    tss_switch_task(GDT_TSS_IDLE_DESC);
}

void game_donde(struct pos_t* pos) {
    if(current_group == player_idle) return;

    pos->x = game_entries[current_group][current_index].pos.x;
    pos->y = game_entries[current_group][current_index].pos.y;

    sched_idle();
    current_group = player_idle;
    tss_switch_task(GDT_TSS_IDLE_DESC);
}

void game_mapear(int x, int y) {
    if(current_group == player_idle) return;

    game_entries[current_group][current_index].mapped_pos.x = x;
    game_entries[current_group][current_index].mapped_pos.y = y;

    game_entries[current_group][current_index].has_mapped = true;

    sched_idle();
    current_group = player_idle;
    tss_switch_task(GDT_TSS_IDLE_DESC);
}

/**********************************
 * Otros
 **********************************/

void game_kill_task() {
    if(current_group == player_idle) return;

    sched_kill_task(current_group, current_index);
    tss_switch_task(GDT_TSS_IDLE_DESC);
}

