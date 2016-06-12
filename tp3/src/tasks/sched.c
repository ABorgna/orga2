/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#include "../defines.h"
#include "../screen.h"
#include "tss.h"
#include "../mem/gdt.h"

#include "sched.h"

player_group curr_scheduled_group = player_idle;

bool dead_or_alive[3][15] = {{0}};
char vivos_count[3] = {0};
char indexes[3] = {0};
char max_entries[3] = {15,5,5};

/**********************************************
 * Funciones internas
 **********************************************/

player_group next_group_alive(player_group current) {
    char i;
    current = current == player_idle ? player_B : current;

    for(i = 1; i <= 3; i++) {
        char index = (current + i) % 3;
        if(vivos_count[index] > 0) {
            return (player_group) index;
        }
    }

    return player_idle;
}

char next_entry(player_group group, bool alive) {
    if(group >= 3) {
        return -1;
    }

    char num_alive = vivos_count[group];
    char max_alive = max_entries[group];
    char i;

    if(alive && num_alive == 0) {
        return -1;
    }
    if(!alive && num_alive == max_alive) {
        return -1;
    }

    for(i = 1; i <= max_alive; i++) {
        char index = (indexes[group] + i) % max_alive;
        if(dead_or_alive[group][index] == alive) {
            return index;
        }
    }

    return -1;
}

/**********************************************
 * Funciones exportadas
 **********************************************/

void sched_inicializar(){
    // shalala
    curr_scheduled_group = player_idle;
}

// Devuelve el proximo grupo e índice a correr
void sched_proxima_tarea(player_group *group, char *index) {
    // Indice y grupo actual
    char curr_index = 0;
    if(curr_scheduled_group == player_idle) {
        curr_index = indexes[curr_scheduled_group];
    }

    // Siguiente grupo
    curr_scheduled_group = next_group_alive(curr_scheduled_group);

    // Siguiente entrada
    if(curr_scheduled_group != player_idle) {
        curr_index = next_entry(curr_scheduled_group, true);
        indexes[curr_scheduled_group] = curr_index;
    }

    *group = curr_scheduled_group;
    *index = curr_index;
}

// Marcar una tarea como lista para correr
void sched_run_task(player_group tipo, char index) {
    if(tipo >= 3 || index >= max_entries[tipo] || dead_or_alive[tipo][index]) {
        return;
    }

    dead_or_alive[tipo][index] = 1;
    vivos_count[tipo]++;
}

// kill -9
void sched_kill_task(player_group tipo, char index) {
    if(tipo >= 3 || index >= max_entries[tipo] || !dead_or_alive[tipo][index]) {
        return;
    }

    vivos_count[tipo]--;
    dead_or_alive[tipo][index] = 0;
}

