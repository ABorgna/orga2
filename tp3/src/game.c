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

bool initialized = 0;

struct pos_t players_pos[2];

player_group current_group;
char current_index;

struct task_state game_entries[3][15] = {{{0}}};
char game_max_entries[3] = {15,5,5};
void* codigo_tarea[3] = {TAREA_H, TAREA_A, TAREA_B};

/**********************************
 * Cosas internas
 **********************************/

static struct task_state* curr_task();
static void game_go_idle();
static pde* current_cr3();

/**********************************
 * Lets play a game
 **********************************/

void game_inicializar() {
    int i;

    // Cosas
    current_group = player_idle;
    current_index = 0;

    players_pos[0].x = 4;
    players_pos[0].y = 30;
    players_pos[1].x = 75;
    players_pos[1].y = 30;

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

    screen_draw_map((struct task_state*) game_entries, 25, players_pos);

    initialized = 1;
}

/**********************************
 * Interaccion con el jugador
 **********************************/

void game_mover_cursor(player_group player, direccion dir) {
    assert(player == player_A || player == player_B);
    player_group jugador = player - 1;			//Esto es porque player_A = 1 y player_B = 2
    switch(dir){
    	case DER: if(players_pos[jugador].x < MAPA_BORDE_DER) players_pos[jugador].x++; break;
    	case IZQ: if(players_pos[jugador].x > MAPA_BORDE_IZQ) players_pos[jugador].x--; break;
    	case ARB: if(players_pos[jugador].y > MAPA_BORDE_ARB) players_pos[jugador].y--; break;
    	case ABA: if(players_pos[jugador].y < MAPA_BORDE_ABA) players_pos[jugador].y++; break;
    }
    screen_draw_map((struct task_state*) game_entries, 25, players_pos);
}

void game_lanzar(player_group player, struct pos_t pos) {
    assert(player == player_H || player == player_A || player == player_B);
    int i;
    struct task_state *task;

    // Buscar el proximo slot vacio
    for(i=0; i < game_max_entries[player]; i++) {
        if(!game_entries[player][i].alive) break;
    }

    // No hay slots libres
    if(i == game_max_entries[player]) {
        return;
    }

    task = &game_entries[player][i];

    task->alive = 1;
    task->pos.x = pos.x;
    task->pos.y = pos.y;
    task->original_group = player;
    task->curr_group = player;
    task->cr3 = mmu_inicializar_dir_tarea(codigo_tarea[player], pos, current_cr3());
    task->has_mapped = false;

    tss_inicializar_tarea(task->tss, task->cr3);

    sched_run_task(player, i);
}

/**********************************
 * Actualizar, cambiar de tarea y todo eso
 * Se llama con el RTC cada 1ms
 **********************************/
void game_tick() {
    if(!initialized) return;
    //el debugger para la ejecución del juego
    if (dbg_displayed) return;

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
        tss_switch_task(curr_task()->tss_desc);
    }
}

/**********************************
 * Syscalls
 **********************************/

void game_soy(unsigned int yoSoy) {
    if(current_group == player_idle) return;

    if(yoSoy == SOY_A) {
        curr_task()->curr_group = player_A;
    } else if (yoSoy == SOY_B) {
        curr_task()->curr_group = player_B;
    } else {
        curr_task()->curr_group = player_H;
    }

    game_go_idle();
}

void game_donde(struct pos_t* pos) {
    if(current_group == player_idle) return;

    // Checkear que no nos quieran hacer escribir
    // en cualquier lado
    if(TO_PAGINA(pos) != TAREA_PAGINA_0 &&
            (!curr_task()->has_mapped || TO_PAGINA(pos) != TAREA_PAGINA_1)) {

            // Winners don't use drugs
            game_kill_task();
            return;
    }

    pos->x = curr_task()->pos.x;
    pos->y = curr_task()->pos.y;

    game_go_idle();
}

void game_mapear(unsigned int x, unsigned int y) {
    if(current_group == player_idle) return;

    if(80 <= x || 44 <= y) {
        // Vo so loco
        game_kill_task();
        return;
    }

    struct pos_t pos = {x,y};
    void* pagina = mmu_celda_to_pagina(pos);

    mmu_mapear_pagina_user(TAREA_PAGINA_1, pagina, curr_task()->cr3);

    curr_task()->mapped_pos.x = x;
    curr_task()->mapped_pos.y = y;

    curr_task()->has_mapped = true;

    game_go_idle();
}

/**********************************
 * Debugger
 **********************************/
bool dbg_enabled = false;           // se setea por interrupción de tecla 'Y'
bool dbg_displayed = false;         // se setea por show_debug

void game_show_debug(){
  // Si no está seteado, no hacer nada
  if (!dbg_enabled) return;

  dbg_displayed = true;
  tss* tsk = curr_task()->tss;
  screen_show_debug(tsk, current_group);
}

void game_hide_debug(){
  dbg_displayed = false;
  screen_draw_map((struct task_state*) game_entries, 25, players_pos);
}


/**********************************
 * Otros
 **********************************/

void game_kill_task() {
    if(current_group == player_idle) return;

    sched_kill_task(current_group, current_index);
    curr_task()->alive = 0;
    game_go_idle();
}

/**********************************
 * Cosas internas
 **********************************/

static __inline __attribute__((always_inline)) struct task_state* curr_task() {
    return &game_entries[current_group][current_index];
}

static void game_go_idle(){
    current_group = player_idle;
    current_index = 0;
    tss_switch_task(GDT_TSS_IDLE_DESC);
}

static pde* current_cr3() {
    if(current_group == player_idle) {
        return KERNEL_PAGE_DIR;
    } else {
        return curr_task()->cr3;
    }
}
