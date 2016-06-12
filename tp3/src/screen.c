/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#include "i386.h"
#include "screen.h"

#define C_MAPA C_FG_DARK_GREY

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

char get_char(unsigned int x, unsigned int y){
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    return p[y][x].c;
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
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    int i, j;
    p[5][0].c = 218;
    p[5][0].a = C_BG_BLACK | C_MAPA ;
    for (j = 1; j < VIDEO_COLS-1; j++) {
        p[5][j].c = 194;
        p[5][j].a = C_BG_BLACK | C_MAPA ;
    }
    p[5][VIDEO_COLS-1].c = 191;
    p[5][VIDEO_COLS-1].a = C_BG_BLACK | C_MAPA ;
    for (i = 6; i < VIDEO_FILS-2; i++) {
        p[i][0].c = 195;
        p[i][0].a = C_BG_BLACK | C_MAPA ;

        for (j = 1; j < VIDEO_COLS-1; j++) {
            p[i][j].c = 197;
            p[i][j].a = C_BG_BLACK | C_MAPA ;
        }
        p[i][VIDEO_COLS-1].c = 180;
        p[i][VIDEO_COLS-1].a = C_BG_BLACK | C_MAPA ;
    }
    p[VIDEO_FILS-2][0].c = 192;
    p[VIDEO_FILS-2][0].a = C_BG_BLACK | C_MAPA ;
    for (j = 1; j < VIDEO_COLS-1; j++) {
        p[VIDEO_FILS-2][j].c = 193;
        p[VIDEO_FILS-2][j].a = C_BG_BLACK | C_MAPA ;
    }
    p[VIDEO_FILS-2][VIDEO_COLS-1].c = 217;
    p[VIDEO_FILS-2][VIDEO_COLS-1].a = C_BG_BLACK | C_MAPA ;
}

void atar_con_alambre(){
    print("(^.^)-b ... LO ATAMO' CON ALAMBRE ", VIDEO_COLS - 34, VIDEO_FILS -1, C_BG_BLACK | C_FG_LIGHT_GREEN);
    print("^", VIDEO_COLS - 33, VIDEO_FILS -1, C_BG_BLACK | C_FG_LIGHT_GREEN | C_BLINK);
    print("^", VIDEO_COLS - 31, VIDEO_FILS -1, C_BG_BLACK | C_FG_LIGHT_GREEN | C_BLINK);
}

void screen_show_debug(tss* tss, player_group group){
    ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
    /* dibujar ventana */
    int i;
    int j;
    for (i = DBG_FILS_INIT; i < DBG_FILS_END; i++) {
      for (j = DBG_COLS_INIT; j < DBG_COLS_END ; j++){
        if ((i == DBG_FILS_END - 1) || (i == DBG_FILS_INIT) || (j == DBG_COLS_INIT) || (j == DBG_COLS_END -1) ){
          p[i][j].a = C_BG_LIGHT_GREY;
          p[i][j].c = ' ';
        } else {
          p[i][j].a = C_BG_BLACK ;
          p[i][j].c = ' ';
        }
      }
    }
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
    unsigned int y = DBG_FILS_INIT + 1;

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

void screen_draw_map(struct task_state *states, char max_states, struct pos_t* players_pos){
    // Esto debería actualizar solo la seccion del mapa, no los puntajes ni el footer

    dibujar_fondo_mapa();

    int i;
    for(i=0; i<max_states; i++) {
        struct task_state task = states[i];
        if(!task.alive) continue;
        unsigned char color;
        switch(task.curr_group){
          case player_H: color = C_BG_BLACK | C_FG_LIGHT_BROWN; break;
          case player_A: color = C_BG_BLACK | C_FG_LIGHT_RED; break;
          case player_B: color = C_BG_BLACK | C_FG_LIGHT_BLUE; break;
          default: color = C_BG_BLACK | C_FG_BLACK;
        }
        if(task.has_mapped)
          print_char(254,task.mapped_pos.x+MAPA_BORDE_IZQ,task.mapped_pos.y+MAPA_BORDE_ARB, color);
        print_char(219,task.pos.x+MAPA_BORDE_IZQ,task.pos.y+MAPA_BORDE_ARB, color);
    }

    print_char('X',players_pos[0].x+MAPA_BORDE_IZQ,players_pos[0].y+MAPA_BORDE_ARB, C_BG_BLACK | C_FG_LIGHT_RED);
    print_char('X',players_pos[1].x+MAPA_BORDE_IZQ,players_pos[1].y+MAPA_BORDE_ARB, C_BG_BLACK | C_FG_LIGHT_BLUE);
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
}

void screen_draw_clocks(struct task_state** game_entries, char* game_max_entries){
  int i;
  int j;
  char offsets[3] = {30,1,69};
  char colores[3] = {C_BG_BLACK | C_FG_LIGHT_BROWN, C_BG_BLACK | C_FG_LIGHT_RED, C_BG_BLACK | C_FG_LIGHT_BLUE};
  for(i = 0 ; i < 3 ; i++){
    for(j = 0 ; j < game_max_entries[i] ; j++){
      struct task_state task = game_entries[i][j];      
      if(task.alive){
        char current_char = get_char(offsets[i]+j, 4);
        char next_char = 0;
        switch(current_char){
          case '|': next_char = '/'; break;
          case '/': next_char = '-'; break;
          case '-': next_char = '\\'; break;
          case '\\': next_char = '|'; break;
          default: next_char = '|';
        }
        print_char(next_char, offsets[i]+j,4, colores[i]);
      }else{
        print_char('X', offsets[i]+j,4, colores[i]);
      }
    }
  }
}