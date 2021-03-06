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
#include "audio/audioplayer.h"

// Realentizar los ticks para que sean visibles :P
uint32_t tick_divisor = 0x100;

bool initialized = false;

bool dbg_enabled = false;           // se setea por interrupción de tecla 'Y'
bool dbg_displayed = false;         // se setea por show_debug

bool restart_msg_displayed = false;

bool help_displayed = false;

struct pos_t players_pos[2];
char players_lives[2];

player_group current_group = player_idle;
char current_index;

struct task_state game_entries[3][15] = {{{0}}};
char game_max_entries[3] = {15,5,5};
void* codigo_tarea[3] = {TAREA_H, TAREA_A, TAREA_B};

/**********************************
 * Cosas internas
 **********************************/

static struct task_state* curr_task();
static void game_update_map();
static void game_go_idle();
static bool game_is_stopped();
static pde* current_cr3();

/**********************************
 * Lets play a game
 **********************************/

void game_inicializar() {
    int i,j;
    initialized = 0;

    // Cosas
    current_group = player_idle;
    current_index = 0;

    players_lives[0] = 20;
    players_lives[1] = 20;

    players_pos[0].x = 4;
    players_pos[0].y = 25;
    players_pos[1].x = 75;
    players_pos[1].y = 25;

    restart_msg_displayed = false;

    // Iniciar las cosas de las tareas
    for(i=0; i<15; i++) {
        game_entries[player_H][i].alive = 0;
        game_entries[player_H][i].tss = tss_H + i;
        game_entries[player_H][i].tss_desc = GDT_TSS_HS_DESC + (i*8);

        screen_kill_clock(player_H,i);
        sched_kill_task(player_H,i);
    }
    for(i=0; i<5; i++) {
        game_entries[player_A][i].alive = 0;
        game_entries[player_A][i].tss = tss_A + i;
        game_entries[player_A][i].tss_desc = GDT_TSS_AS_DESC + (i*8);

        screen_kill_clock(player_A,i);
        sched_kill_task(player_A,i);
    }
    for(i=0; i<5; i++) {
        game_entries[player_B][i].alive = 0;
        game_entries[player_B][i].tss = tss_B + i;
        game_entries[player_B][i].tss_desc = GDT_TSS_BS_DESC + (i*8);

        screen_kill_clock(player_B,i);
        sched_kill_task(player_B,i);
    }

    // Lanzar las tareas H
    for(i=0; i<15; i++) {
        bool any_equal = false;
        struct pos_t pos;
        do {
            pos.x = rand(80);
            pos.y = rand(44);

            // Si no checkeamos, hay un 2.94% de proba que toquen dos iguales
            any_equal = false;
            for(j=0; j<i; j++) {
                struct pos_t *otra_pos = &game_entries[player_H][j].pos;
                if(pos.x == otra_pos->x && pos.y == otra_pos->y) {
                    any_equal = true;
                    break;
                }
            }
        } while(any_equal);

        game_lanzar(player_H, pos);
    }

    game_update_map();

    initialized = 1;
}

/**********************************
 * Reiniciar el juego
 **********************************/

void game_show_restart_msg() {
    restart_msg_displayed = 1;
    game_update_map();

    game_go_idle();
}

void game_hide_restart_msg() {
    restart_msg_displayed = 0;
    game_update_map();
}

bool game_restart_msg_shown() {
    return restart_msg_displayed;
}

void game_restart() {
    restart_msg_displayed = 0;
    game_inicializar();

    // Si la rutina actual no era la idle, descartarla
    if(rtr() != GDT_TSS_IDLE_DESC) {
        ltr(GDT_TSS_INICIAL);
    }

    game_go_idle();
}

/**********************************
 * Interaccion con el jugador
 **********************************/

void game_mover_cursor(player_group player, direccion dir) {
    assert(player == player_A || player == player_B);

    //Esto es porque player_A = 1 y player_B = 2
    struct pos_t* pos = &players_pos[player-1];

    switch(dir){
        case DER: if(pos->x < 79) pos->x++; break;
        case IZQ: if(pos->x > 0 ) pos->x--; break;
        case ARB: if(pos->y > 0 ) pos->y--; break;
        case ABA: if(pos->y < 43) pos->y++; break;
    }

    if(player == player_A) {
      //play_mov_A();
    } else {
      //play_mov_B();
    }

    game_update_map();
}

void game_lanzar_inplace(player_group player) {
    assert(player == player_A || player == player_B);

    game_lanzar(player, players_pos[player-1]);
}

void game_lanzar(player_group player, struct pos_t pos) {
    assert(player == player_H || player == player_A || player == player_B);
    if(player == player_H || players_lives[player - 1] > 0){
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

        if(player != player_H)
            players_lives[player - 1]--;

        sched_run_task(player, i);

        screen_actualizar_grupo_clock(player,i,player);

        game_update_map();
    }
}

/**********************************
 * Actualizar, cambiar de tarea y todo eso
 * Se llama con el RTC cada 1ms
 **********************************/
void game_tick() {
    static uint32_t tick_divisor_count = ~0;

    if(game_is_stopped()) return;

    // Bajarle un cambio a la frequencia de actualizacion
    tick_divisor_count = (tick_divisor_count -1) % tick_divisor;
    if(tick_divisor_count) return;

    player_group next_group;
    char next_index;

    sched_proxima_tarea(&next_group, &next_index);

    screen_avanzar_clock(next_group,next_index);

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

    screen_actualizar_grupo_clock(current_group,current_index,
            curr_task()->curr_group);
    game_update_map();
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

    game_update_map();
    game_go_idle();
}

/**********************************
 * Debugger
 **********************************/
void game_show_debug(){
    // Si no está seteado, no hacer nada
    if (!dbg_enabled) return;

    dbg_displayed = true;
    tss* tsk = curr_task()->tss;
    screen_show_debug(tsk, current_group);
}

void game_hide_debug(){
    dbg_displayed = false;
    game_update_map();
}

void game_enable_debugger(bool enable){
    dbg_enabled = enable;
    screen_draw_debugger_enabled();
}

bool game_debugger_enabled(){
    return dbg_enabled;
}

bool game_debugger_displayed(){
    return dbg_displayed;
}

/**********************************
 * Help
 **********************************/
void game_show_help(){
    help_displayed = true;
    screen_show_help();
}

void game_hide_help(){
    help_displayed = false;
    game_update_map();
}

bool game_help_displayed(){
    return help_displayed;
}

/**********************************
 * Otros
 **********************************/

void game_kill_task() {
    if(current_group == player_idle) return;

    game_show_debug();

    screen_kill_clock(current_group, current_index);
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
    current_index = 0;
    current_group = player_idle;

    if(rtr() != GDT_TSS_IDLE_DESC) {
        tss_switch_task(GDT_TSS_IDLE_DESC);
    }
}

static void game_update_map(){
    screen_draw_map((struct task_state*) game_entries, 45, players_pos);
    screen_draw_interface((struct task_state*) game_entries, 45, players_lives);
    screen_draw_debugger_enabled();

    if(game_restart_msg_shown()) {
        screen_show_restart_msg();
    }

    if(help_displayed) {
        screen_show_help();
    }
}

static __inline __attribute__((always_inline)) bool game_is_stopped() {
    return !initialized || restart_msg_displayed || dbg_displayed || help_displayed;
}

static pde* current_cr3() {
    if(current_group == player_idle) {
        return KERNEL_PAGE_DIR;
    } else {
        return curr_task()->cr3;
    }
}

