/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#include "game.h"

#include "defines.h"
#include "random.h"
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
 * Cosas internas
 **********************************/

void game_go_idle();

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

    // Lanzar las tareas H
    for(i=0; i<5; i++) {
        // Hay un 2.94% de proba que toquen dos iguales
        // TODO: hacer algo
        struct pos_t pos = {rand(80), rand(44)};
        game_lanzar(player_H, pos);
    }

    initialized = 1;
}

/**********************************
 * Interaccion con el jugador
 **********************************/

void game_mover_cursor(player_group player, direccion dir) {
    assert(player == player_A || player == player_B);
}

void game_lanzar(player_group player, struct pos_t pos) {
    assert(player == player_H || player == player_A || player == player_B);
}

/**********************************
 * Actualizar, cambiar de tarea y todo eso
 * Se llama con el RTC cada 1ms
 **********************************/
void game_tick() {
    if(!initialized) return;

    player_group next_group;
    char next_index;

    sched_proxima_tarea(&next_group, &next_index);

    // Solo switchear task si estamos en otra
    if(next_group == current_group &&
            (next_group == player_idle || next_index == current_index)) {
        return;
    }
    current_group = next_group;
    current_index = next_index;

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

 	if(yoSoy == 0x841)
    	game_entries[current_group][current_index].curr_group = player_A;
    else if (yoSoy == 0x325)
    	game_entries[current_group][current_index].curr_group = player_B;
    else
    	game_entries[current_group][current_index].curr_group = player_H;

    current_group = player_idle;
    game_go_idle();
}

void game_donde(struct pos_t* pos) {
    if(current_group == player_idle) return;

    pos->x = game_entries[current_group][current_index].pos.x;
    pos->y = game_entries[current_group][current_index].pos.y;

    current_group = player_idle;
    game_go_idle();
}

void game_mapear(int x, int y) {
    if(current_group == player_idle) return;

    game_entries[current_group][current_index].mapped_pos.x = x;
    game_entries[current_group][current_index].mapped_pos.y = y;

    game_entries[current_group][current_index].has_mapped = true;

    current_group = player_idle;
    game_go_idle();
}

/**********************************
 * Otros
 **********************************/

void game_kill_task() {
    if(current_group == player_idle) return;

    sched_kill_task(current_group, current_index);
    game_go_idle();
}

/**********************************
 * Cosas internas
 **********************************/

void game_go_idle(){
    current_group = player_idle;
    current_index = 0;
    tss_switch_task(GDT_TSS_IDLE_DESC);
}

