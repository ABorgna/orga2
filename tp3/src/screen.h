/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#ifndef __SCREEN_H__
#define __SCREEN_H__

/* Definicion de la pantalla */
#define VIDEO_FILS 50
#define VIDEO_COLS 80

#define DBG_COLS_INIT 25
#define DBG_COLS_END 55
#define DBG_FILS_INIT 6
#define DBG_FILS_END 44

#define RESTART_COLS_INIT 27
#define RESTART_COLS_END 53
#define RESTART_FILS_INIT 23
#define RESTART_FILS_END 27
#define RESTART_COL_TEXT 29
#define RESTART_FILA_TEXT 25

#define HELP_COLS_INIT 23
#define HELP_COLS_END 57
#define HELP_FILS_INIT 12
#define HELP_FILS_END 39

#include "colors.h"
#include "defines.h"
#include "tasks/tss.h"
#include "game.h"

/* Estructura de para acceder a memoria de video */
typedef struct ca_s {
    unsigned char c;
    unsigned char a;
} ca;

void print(const char * text, unsigned int x, unsigned int y, unsigned char attr);
void print_hex(unsigned int numero, int size, unsigned int x, unsigned int y, unsigned char attr);
void print_int(unsigned int n, unsigned int x, unsigned int y, unsigned char attr, unsigned int limite);
void print_char(unsigned char c, unsigned int x, unsigned int y, unsigned char attr);
ca get_ca(unsigned int x, unsigned int y);
char get_char(unsigned int x, unsigned int y);

void reventar_pantalla();

void dibujar_fondo_interfaz();
void dibujar_fondo_mapa();

void screen_show_debug(tss* tss, player_group group);
void screen_draw_debugger_enabled();

void screen_draw_map(struct task_state *states, char max_states, struct pos_t* players_pos);
void screen_draw_interface(struct task_state *states, char max_states, char* players_lives);

void screen_show_restart_msg();

void screen_show_help();

void screen_draw_clocks();
void screen_actualizar_grupo_clock(player_group group, char index, player_group curr_group);
void screen_avanzar_clock(player_group group, char index);
void screen_kill_clock(player_group group, char index);

void screen_dibujar_marco(uint8_t initX, uint8_t endX,
                          uint8_t initY, uint8_t endY,
                          bool grilla);

#endif  /* !__SCREEN_H__ */
