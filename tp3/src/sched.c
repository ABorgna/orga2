/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#include "defines.h"
#include "sched.h"

struct sched_entry {
	short tss_entry;
	char its_aliveeeeeeeeeeeee;
};


typedef enum{
	sched_H_t = 0,
	sched_A_t = 1,
	sched_B_t = 2,
	sched_Idle_t = 0xff
} sched_type;

sched_type t_HAB = sched_Idle_t;

struct sched_entry sched_entries[3][15] = {{{0}}};
char sched_vivos[3] = {0};
char sched_indexes[3] = {0};
char sched_max_entries[3] = {15,5,5};

void sched_inicializar(){
}

unsigned short sched_proximo_indice() {
	// devuelve -1 si no hay que cambiar
	bool cambie = 0;
	char i,j;

	char curr = t_HAB == sched_Idle_t ? 0 : t_HAB;

	for(i = 1; i <= 3; i++) {
		char index = (curr + i) % 3;

		// Proximo grupo vivo
		if(sched_vivos[index] > 0) {
			
		}
	}

	if(shced)
	return -1;
}

short sched_run_task(sched_type tipo) {
	// devuelve -1 si no puede hacerun carajo
	short i;

	switch(tipo) {
		case sched_H_t:
			if(sched_vivos[sched_H_t] == 15) {
				return -1;
			}

			// buscar el prox muerto
			for(i=0; i < 15 ; i++) {
				if(! sched_entries[sched_H_t][i].its_aliveeeeeeeeeeeee) break;
			}

			if(i == 15) {
				breakpoint();
				__asm("mov 0x0001DEAD, %eax");
			}

			// shalala
			sched_vivos[sched_H_t]++;
			sched_entries[sched_H_t][i].its_aliveeeeeeeeeeeee = 1;

			return i;

		case sched_A_t:
			if(sched_vivos[sched_A_t] == 5) {
				return -1;
			}

			// buscar el prox muerto
			for(i=0; i < 5 ; i++) {
				if(! sched_entries[sched_A_t][i].its_aliveeeeeeeeeeeee) break;
			}

			if(i == 5) {
				breakpoint();
				__asm("mov 0x0002DEAD, %eax");
			}

			// shalala
			sched_vivos[sched_A_t]++;
			sched_entries[sched_A_t][i].its_aliveeeeeeeeeeeee = 1;

			return i;	

		case sched_B_t:
			if(sched_vivos[sched_B_t] == 5) {
				return -1;
			}

			// buscar el prox muerto
			for(i=0; i < 5 ; i++) {
				if(! sched_entries[sched_B_t][i].its_aliveeeeeeeeeeeee) break;
			}

			if(i == 5) {
				breakpoint();
				__asm("mov 0x0002DEAD, %eax");
			}

			// shalala
			sched_vivos[sched_B_t]++;
			sched_entries[sched_B_t][i].its_aliveeeeeeeeeeeee = 1;

			return i;	
		case sched_Idle_t:
			break;	
	}
	return -1;
}
