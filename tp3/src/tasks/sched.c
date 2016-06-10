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

struct sched_entry {
    short tss_descriptor;
    bool its_aliveeeeeeeeeeeee;
};

sched_group current_group = sched_Idle;

struct sched_entry sched_entries[3][15] = {{{0}}};
char sched_vivos[3] = {0};
char sched_indexes[3] = {0};
char sched_max_entries[3] = {15,5,5};

/**********************************************
 * Funciones internas
 **********************************************/

sched_group next_group_alive(sched_group current) {
    char i;
    current = current == sched_Idle ? sched_B : sched_H;

    for(i = 1; i <= 3; i++) {
        char index = (current + i) % 3;
        if(sched_vivos[index] > 0) {
            return (sched_group) index;
        }
    }

    return sched_Idle;
}

char next_entry(sched_group group, bool alive) {
    if(group >= 3) {
        return -1;
    }

    char num_alive = sched_vivos[group];
    char max_alive = sched_max_entries[group];
    char i;

    if(alive && num_alive == 0) {
        return -1;
    }
    if(!alive && num_alive == max_alive) {
        return -1;
    }

    for(i = 1; i <= max_alive; i++) {
        char index = (sched_indexes[group] + i) % max_alive;
        if(sched_entries[group][index].its_aliveeeeeeeeeeeee == alive) {
            return index;
        }
    }

    return -1;
}

/**********************************************
 * Funciones exportadas
 **********************************************/

void sched_inicializar(){
    int i;

    for(i=0; i<15; i++) {
        sched_entries[sched_H][i].tss_descriptor = GDT_TSS_HS_DESC + i*8;
    }
    for(i=0; i<5; i++) {
        sched_entries[sched_A][i].tss_descriptor = GDT_TSS_AS_DESC + i*8;
    }
    for(i=0; i<5; i++) {
        sched_entries[sched_B][i].tss_descriptor = GDT_TSS_BS_DESC + i*8;
    }
}

// Devuelve el offset del nuevo tss_entry,
// 0 si no hay que cambiar
short sched_proxima_tarea() {
    sched_group curr_group = current_group;
    char curr_index = current_group == sched_Idle ?
                                  0 : sched_indexes[current_group];

    sched_group group = next_group_alive(curr_group);
    char entry = 0;

    current_group = group;
    if(group != sched_Idle) {
        entry = next_entry(group, true);
        sched_indexes[group] = entry;
    }

    if(group == curr_group && entry == curr_index) {
        return 0;
    }

    if(group == sched_Idle) {
        return GDT_TSS_IDLE_DESC;
    } else {
        return sched_entries[group][entry].tss_descriptor;
    }
}

// Devuelve el indice de la nueva tarea,
// -1 si no puede hacer un carajo
char sched_run_task(sched_group tipo) {
    if(tipo >= 3) {
        return -1;
    }

    char index = next_entry(tipo, false);

    if(index != -1) {
        sched_entries[tipo][index].its_aliveeeeeeeeeeeee = 1;
        sched_vivos[tipo]++;
    }

    return index;
}

// kill -9
void sched_kill_task(sched_group tipo, char index) {
    if(tipo >= 3 || index >= sched_max_entries[tipo] ||
            !sched_entries[tipo][index].its_aliveeeeeeeeeeeee) {
        return;
    }

    sched_vivos[tipo]--;
    sched_entries[tipo][index].its_aliveeeeeeeeeeeee = 0;

    if(current_group == tipo && sched_indexes[tipo] == index) {
        sched_idle();
    }
}

void sched_idle() {
    current_group = sched_Idle;
}

