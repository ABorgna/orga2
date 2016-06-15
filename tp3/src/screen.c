/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#include "i386.h"
#include "screen.h"
#include "random.h"

#define C_MAPA C_FG_DARK_GREY

struct clock_state {
    uint8_t state;
    bool alive;
    player_group group;
};

char clock_states[4] = "|/-\\";
struct clock_state clocks[3][15] = {{{0}}};

void print(const char * text, unsigned int x, unsigned int y, unsigned char attr) {
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    int i;
    for (i = 0; text[i] != 0; i++) {
        p[y][x].c = (unsigned char) text[i];
        p[y][x].a = attr;
        x++;
        if (x == VIDEO_COLS) {
            x = 0;
            y++;
        }
    }
}

void print_hex(unsigned int numero, int size, unsigned int x, unsigned int y, unsigned char attr) {
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    int i;
    char hexa[8];
    char letras[16] = "0123456789ABCDEF";
    hexa[0] = letras[ ( numero & 0x0000000F ) >> 0  ];
    hexa[1] = letras[ ( numero & 0x000000F0 ) >> 4  ];
    hexa[2] = letras[ ( numero & 0x00000F00 ) >> 8  ];
    hexa[3] = letras[ ( numero & 0x0000F000 ) >> 12 ];
    hexa[4] = letras[ ( numero & 0x000F0000 ) >> 16 ];
    hexa[5] = letras[ ( numero & 0x00F00000 ) >> 20 ];
    hexa[6] = letras[ ( numero & 0x0F000000 ) >> 24 ];
    hexa[7] = letras[ ( numero & 0xF0000000 ) >> 28 ];
    for(i = 0; i < size; i++) {
        p[y][x + size - i - 1].c = hexa[i];
        p[y][x + size - i - 1].a = attr;
    }
}

void print_int(unsigned int n, unsigned int x, unsigned int y, unsigned char attr, unsigned int limite) {
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    if (!limite) return;
      if( n > 9 ) {
        int a = n / 10;
        n -= 10 * a;
        print_int(a,x-1,y,attr, limite-1);
      }
      p[y][x].c = '0'+n;
      p[y][x].a = attr;

}

void print_char(unsigned char c, unsigned int x, unsigned int y, unsigned char attr) {
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
      p[y][x].c = c;
      p[y][x].a = attr;
}

ca get_ca(unsigned int x, unsigned int y){
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    return p[y][x];
}

char get_char(unsigned int x, unsigned int y){
    return get_ca(x,y).c;
}

void reventar_pantalla(){
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    int i, j;
    for (i = 0; i < VIDEO_FILS; i++) {
        for (j = 0; j < VIDEO_COLS; j++) {
            p[i][j].c = 197;
            p[i][j].a = C_BG_BLACK | C_FG_GREEN;
        }
    }
}

void dibujar_fondo_interfaz(){
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    int i, j;
    for (i = 0; i < 5; i++) {
        for (j = 0; j < VIDEO_COLS; j++) {
            p[i][j].c = ' ';
            p[i][j].a = C_BG_BLACK | C_MAPA ;
        }
    }
    for (j = 0; j < VIDEO_COLS; j++) {
        p[VIDEO_FILS-1][j].c = ' ';
        p[VIDEO_FILS-1][j].a = C_BG_BLACK | C_MAPA ;
    }

    dibujar_fondo_mapa();
}

void dibujar_fondo_mapa(){
    screen_dibujar_marco(0, 79,
                         5, 48,
                         true);
}

void atar_con_alambre(){
    print("(^.^)-b ... LO ATAMO' CON ALAMBRE ", 23, 1, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print("^", 24, 1, C_BG_BLACK | C_FG_LIGHT_GREEN | C_BLINK);
    print("^", 26, 1, C_BG_BLACK | C_FG_LIGHT_GREEN | C_BLINK);
}

void screen_show_debug(tss* tss, player_group group){
    /* dibujar ventana */
    screen_dibujar_marco(DBG_COLS_INIT, DBG_COLS_END,
                         DBG_FILS_INIT, DBG_FILS_END,
                         false);

    /* info etiquetas */
    unsigned char group_char = ' ';
    switch (group) {
      case 0:
        group_char = 'H';
        break;
      case 1:
        group_char = 'A';
        break;
      case 2:
        group_char = 'B';
        break;
      default:
        group_char = ' ';
    }

    unsigned int cr0 = rcr0();
    unsigned int cr2 = rcr2();
    unsigned int cr4 = rcr4();

    unsigned int* pila = (unsigned int*) tss->esp;

    /* valores de registros según tss, POR FILA */
    unsigned int y = DBG_FILS_INIT + 2;

    print("virus", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN | C_BLINK);
    print_char(group_char, DBG_COLS_INIT + 8, y, C_BG_BLACK | C_FG_GREEN | C_BLINK);
    y += 2;

    print("eax", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->eax, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print("cr0", DBG_COLS_INIT + 16, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(cr0, 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("ebx", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->ebx, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print("cr2", DBG_COLS_INIT + 16, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(cr2, 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("ecx", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->ecx, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print("cr3", DBG_COLS_INIT + 16, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->cr3, 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("edx", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->edx, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print("cr4", DBG_COLS_INIT + 16, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(cr4, 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("esi", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->esi, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("edi", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->edi, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("ebp", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->ebp, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("esp", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->esp, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("eip", DBG_COLS_INIT + 2, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->eip, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("cs", DBG_COLS_INIT + 3, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->cs, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print("stack", DBG_COLS_INIT + 16, y, C_BG_BLACK | C_FG_GREEN);
    y += 2;

    print("ds", DBG_COLS_INIT + 3, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->ds, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print_hex(pila[0], 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("es", DBG_COLS_INIT + 3, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->es, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print_hex(pila[1], 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("fs", DBG_COLS_INIT + 3, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->fs, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print_hex(pila[2], 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("gs", DBG_COLS_INIT + 3, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->gs, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print_hex(pila[3], 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("ss", DBG_COLS_INIT + 3, y, C_BG_BLACK | C_FG_GREEN);
    print_hex(tss->ss, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print_hex(pila[4], 8, DBG_COLS_INIT + 20, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
    y += 2;

    print("eflags", DBG_COLS_INIT + 3, y, C_BG_BLACK | C_FG_GREEN);
    y += 2;
    print_hex(tss->eflags, 8, DBG_COLS_INIT + 6, y, C_BG_BLACK | C_FG_LIGHT_GREEN);
}

void screen_draw_debugger_enabled(){
    if(game_debugger_enabled()){
        print("DEBUG MODE", 10, 49, C_FG_LIGHT_GREEN);
    } else {
        print("          ", 10, 49, 0);
    }
}

void screen_draw_map(struct task_state *states, char max_states, struct pos_t* players_pos){
    // Esto debería actualizar solo la seccion del mapa, no los puntajes ni el footer
    unsigned char colores[3] = {C_BG_BLACK | C_FG_LIGHT_BROWN,
                                C_BG_BLACK | C_FG_LIGHT_RED,
                                C_BG_BLACK | C_FG_LIGHT_BLUE};

    dibujar_fondo_mapa();

    // Dibujar tareas y lugares mapeados
    int i;
    for(i=0; i<max_states; i++) {
        struct task_state *task = &states[i];
        if(!task->alive) continue;

        unsigned char color = colores[task->curr_group];
        unsigned char x = task->pos.x+MAPA_BORDE_IZQ;
        unsigned char y = task->pos.y+MAPA_BORDE_ARB;
        unsigned char caracter = 219; // cuadrado grande

        ca actual = get_ca(x,y);
        if(actual.c == 254) {
            // Una tarea mapeo esta posicion
            // pintar el fondo de nuestro color
            color = ((color << 4) & 0x70) | (actual.a & 0xf);
            caracter = 254;
        }
        print_char(caracter,x,y,color);

        if(task->has_mapped) {
            color = colores[task->curr_group];
            x = task->mapped_pos.x+MAPA_BORDE_IZQ;
            y = task->mapped_pos.y+MAPA_BORDE_ARB;
            caracter = 254; // cuadrado chico

            actual = get_ca(x,y);
            if(actual.c == 219) {
                // Hay una tarea en donde estamos parados
                // pintar el fondo del color de la tarea
                color = color | ((actual.a << 4) & 0x70);
            }
            print_char(caracter,x,y, color);
        }
    }

    // Dibujar cursores
    unsigned char xA = players_pos[0].x+MAPA_BORDE_IZQ;
    unsigned char yA = players_pos[0].y+MAPA_BORDE_ARB;
    unsigned char xB = players_pos[1].x+MAPA_BORDE_IZQ;
    unsigned char yB = players_pos[1].y+MAPA_BORDE_ARB;
    unsigned char colorA = C_BG_BLACK | C_FG_LIGHT_RED;
    unsigned char colorB = C_BG_BLACK | C_FG_LIGHT_BLUE;

    if(xA == xB && yA == yB) {
        colorA = colorB = C_FG_LIGHT_MAGENTA;
    }

    // Si hay una tarea en la posicion, mostrarla como fondo
    ca actual = get_ca(xA,yA);
    if(actual.c == 219) { // Cuadrado grande
        colorA = colorA | ((actual.a << 4) & 0x70);
    } else if(actual.c == 256) { // Cuadrado chico
        colorA = colorA | (actual.a & 0x70);
    }

    actual = get_ca(xB,yB);
    if(actual.c == 219) { // Cuadrado grande
        colorB = colorB | ((actual.a << 4) & 0x70);
    } else if(actual.c == 256) { // Cuadrado chico
        colorB = colorB | (actual.a & 0x70);
    }

    print_char('X',xB,yB, colorB);
    print_char('X',xA,yA, colorA);
}

void screen_draw_interface(struct task_state *states, char max_states, char* players_lives){
  //Limpiar texto de vidas y puntaje
  print_int(99,1,0, C_BG_BLACK | C_FG_BLACK ,2);
  print_int(99,1,1, C_BG_BLACK | C_FG_BLACK ,2);
  print_int(99,50,0, C_BG_BLACK | C_FG_BLACK ,2);
  print_int(99,50,1, C_BG_BLACK | C_FG_BLACK ,2);

  //Valores predeterminados de jugadores (cambiar a gusto)
  unsigned char C_PLAYER1 = C_BG_BLACK | C_FG_LIGHT_RED;
  unsigned char C_PLAYER2 = C_BG_BLACK | C_FG_LIGHT_BLUE;

  unsigned char player1_xoffset = 1;
  unsigned char player2_xoffset = 69;
  unsigned char yoffset = 1;

  //Textito identificador de players

  print("Player 1", player1_xoffset, yoffset, C_PLAYER1);
  print("Player 2", player2_xoffset, yoffset, C_PLAYER2);

  //Printear vidas
  print("Vidas: ", player1_xoffset, yoffset+1, C_PLAYER1);
  print_int(players_lives[0], player1_xoffset + 10, yoffset+1, C_PLAYER1, 2);

  print("Vidas: ", player2_xoffset, yoffset+1, C_PLAYER2);
  print_int(players_lives[1], player2_xoffset+10, yoffset+1, C_PLAYER2, 2);

  //Printear puntaje

  char puntos[2] = {0,0};
  int i;
  for(i=0; i<max_states; i++) {
    struct task_state task = states[i];
    if(!task.alive) continue;
    switch(task.curr_group){
      case player_A: puntos[0]++ ; break;
      case player_B: puntos[1]++ ; break;
      default:;
    }
  }

  print("Puntos: ", player1_xoffset, yoffset+2, C_PLAYER1);
  print_int(puntos[0], player1_xoffset+10, yoffset+2, C_PLAYER1, 2);

  print("Puntos: ",player2_xoffset, yoffset+2, C_PLAYER2);
  print_int(puntos[1], player2_xoffset+10, yoffset+2, C_PLAYER2,2);

  print("? - Ayuda", 71, 49, C_FG_LIGHT_GREEN);
}

void screen_show_restart_msg() {
    /* dibujar ventana para reiniciar el juego */
    screen_dibujar_marco(RESTART_COLS_INIT, RESTART_COLS_END,
                         RESTART_FILS_INIT, RESTART_FILS_END,
                         false);

    print("Reiniciar juego?", RESTART_COL_TEXT, RESTART_FILA_TEXT, C_FG_LIGHT_GREEN);
    print("(y/N)", RESTART_COLS_END - 7, RESTART_FILS_END, C_FG_LIGHT_GREEN);
}

void screen_show_help() {
    /* dibujar ventana con listado de las teclas */
    uint8_t x = HELP_COLS_INIT + 2, y = HELP_FILS_INIT + 2;
    uint8_t c = C_FG_LIGHT_GREEN;

    screen_dibujar_marco(HELP_COLS_INIT, HELP_COLS_END,
                         HELP_FILS_INIT, HELP_FILS_END,
                         false);

    print("---------- Movimiento ----------", x, y++, c);
    y++;
    print("WASD/,AOE  Mover jugador A      ", x, y++, c);
    print("Shift-L    Lanzar jugador A     ", x, y++, c);
    print("Flechitas  Mover jugador B      ", x, y++, c);
    print("Shift-R    Lanzar jugador B     ", x, y++, c);
    y++;
    print("----------- Opciones -----------", x, y++, c);
    y++;
    print("Esc        Reiniciar juego      ", x, y++, c);
    print("Y          Habilitar modo debug ", x, y++, c);
    print("?          Menu de ayuda        ", x, y++, c);
    y++;
    print("------------ Audio -------------", x, y++, c);
    y++;
    print("F1         Silenciar sonidos    ", x, y++, c);
    print("F2         Tocar Pacman         ", x, y++, c);
    print("F3         Tocar Spectra        ", x, y++, c);
    print("F4         Tocar Kirby          ", x, y++, c);
    print("F5         Tocar Mario          ", x, y++, c);
    print("F6         Tocar Pokemon gsc    ", x, y++, c);
    print("F7         Tocar Pokemon ruby   ", x, y++, c);
    print("F8         Tocar Sonic          ", x, y++, c);
    print("F9         Tocar Superfantasy   ", x, y++, c);
}

void screen_draw_clocks() {
    char offsets[3] = {30,1,69};
    char max_i[3] = {15,5,5};
    char colores[3] = {C_BG_BLACK | C_FG_LIGHT_BROWN, C_BG_BLACK | C_FG_LIGHT_RED, C_BG_BLACK | C_FG_LIGHT_BLUE};
    char color_off = C_FG_LIGHT_GREY;

    char current_char, color;
    int group, i;

    for(group=0; group<3; group++) {
        for(i=0; i<max_i[group]; i++) {
            struct clock_state* clock = &clocks[group][i];

            if(clock->alive) {
                color = colores[clock->group];
                current_char = clock_states[clock->state];
            } else {
                color = color_off;
                current_char = 'x';
            }

            print_char(current_char, offsets[group] + i, 4, color);
        }
    }
}

void screen_actualizar_grupo_clock(player_group group, char index, player_group curr_group){
    assert(index < 5 || (group == player_H && index < 15));

    struct clock_state* clock = &clocks[group][index];
    clock->group = curr_group;

    screen_draw_clocks();
}

void screen_avanzar_clock(player_group group, char index){
    assert(index < 5 || (group == player_H && index < 15));

    struct clock_state* clock = &clocks[group][index];

    if(!clock->alive) {
        clock->alive = 1;
        clock->state = rand(4);
    }
    clock->state = (clock->state + 1) % 4;

    screen_draw_clocks();
}

void screen_kill_clock(player_group group, char index){
    assert(index < 5 || (group == player_H && index < 15));

    struct clock_state* clock = &clocks[group][index];

    clock->alive = 0;
    clock->state = 0;

    screen_draw_clocks();
}

void screen_dibujar_marco(uint8_t initX, uint8_t endX,
                          uint8_t initY, uint8_t endY,
                          bool grilla) {
    int i, j;
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;

    j = initY;
    for (i = initX; i <= endX ; i++){
        unsigned char c = grilla ? 194 : 196; // -.- or -
        if(i == initX) c = 218; // ,-
        if(i == endX) c = 191; // -,

        p[j][i].a = C_FG_DARK_GREY;
        p[j][i].c = c;
    }

    for (j = initY+1; j < endY; j++) {
        for (i = initX; i <= endX ; i++){
            unsigned char c = grilla ? 197 : ' ';
            if(i == initX) c = grilla ? 195 : 179; // |- or |
            if(i == endX) c = grilla ? 180 : 179; // -| or |

            p[j][i].a = C_FG_DARK_GREY;
            p[j][i].c = c;
        }
    }

    j = endY;
    for (i = initX; i <= endX ; i++){
        unsigned char c = grilla ? 193 : 196; // -'- or -
        if(i == initX) c = 192; // '-
        if(i == endX) c = 217; // -'

        p[j][i].a = C_FG_DARK_GREY;
        p[j][i].c = c;
    }

}
