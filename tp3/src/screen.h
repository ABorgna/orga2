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

#define DBG_COLS_INIT 20
#define DBG_COLS_END 60

#define DBG_FILS_INIT 7
#define DBG_FILS_END 48

#include "colors.h"
#include "defines.h"
#include "tasks/tss.h"

/* Estructura de para acceder a memoria de video */
typedef struct ca_s {
    unsigned char c;
    unsigned char a;
} ca;

void print(const char * text, unsigned int x, unsigned int y, unsigned char attr);

void print_hex(unsigned int numero, int size, unsigned int x, unsigned int y, unsigned char attr);

void print_int(unsigned int n, unsigned int x, unsigned int y, unsigned char attr, unsigned int limite);

void print_char(unsigned char c, unsigned int x, unsigned int y, unsigned char attr);

void reventar_pantalla();

void screen_show_debug(tss* tss, player_group group);

#endif  /* !__SCREEN_H__ */
