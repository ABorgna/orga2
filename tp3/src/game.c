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

bool initialized = 0;

struct pos_t players_pos[2];

player_group current_group;
char current_index;

struct task_state game_entries[3][15] = {{{0}}};
char game_max_entries[3] = {15,5,5};

/**********************************
 * Lets play a game
 **********************************/

void game_inicializar() {
    int i;

    // Cosas
    current_group = player_idle;
    current_index = 0;

    players_pos[0].x = 0;
    players_pos[0].y = 0;
    players_pos[1].x = 79;
    players_pos[1].y = 0;

    // Iniciar las cosas de las tareas
    for(i=0; i<15; i++) {
        game_entries[player_H][i].tss = tss_H + i;
        game_entries[player_H][i].tss_desc = GDT_TSS_HS_DESC + (i*8);
    }
    for(i=0; i<5; i++) {
        game_entries[player_A][i].tss = tss_A + i;
        game_entries[player_A][i].tss_desc = GDT_TSS_AS_DESC + (i*8);
    }
    for(i=0; i<5; i++) {
        game_entries[player_B][i].tss = tss_B + i;
        game_entries[player_B][i].tss_desc = GDT_TSS_BS_DESC + (i*8);
    }

    initialized = 1;
}

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
    if(!initialized) return;

    return; // TODO abajo hay basura

    if(current_group == player_idle) {
        tss_switch_task(GDT_TSS_IDLE_DESC);
    } else {
        tss_switch_task(game_entries[current_group][current_index].tss_desc);
    }
}

/**********************************
 * Syscalls
 **********************************/

void game_soy(unsigned int yoSoy) {
    if(current_group == player_idle) return;

    current_group = player_idle;
    tss_switch_task(GDT_TSS_IDLE_DESC);
}

void game_donde(unsigned int* pos) {
    if(current_group == player_idle) return;

    current_group = player_idle;
    tss_switch_task(GDT_TSS_IDLE_DESC);
}

void game_mapear(int x, int y) {
    if(current_group == player_idle) return;

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

/**********************************
 * Cosas internas
 **********************************/

