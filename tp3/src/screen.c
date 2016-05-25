/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

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

void reventar_pantalla(){
  ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO_SCREEN;
  int i, j;
  for (i = 0; i < VIDEO_FILS; i++) {
    for (j = 0; j < VIDEO_COLS; j++) {
      p[i][j].c = 197;
      p[i][j].a = (i + j) % 2 ?
                  C_BG_BLACK | C_FG_GREEN : 
                  C_BG_BLACK | C_FG_GREEN ;
                  
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
	for (j = 0; j < VIDEO_COLS; j++) {
		  p[VIDEO_FILS-1][j].c = ' ';
		  p[VIDEO_FILS-1][j].a = C_BG_BLACK | C_MAPA ; 	
	}
	
	p[34][5].c = 219;
	p[34][5].a = C_BG_BLACK | C_FG_MAGENTA | C_BLINK; 	
	
	p[36][44].c = 219;
	p[36][44].a = C_BG_BLACK | C_FG_CYAN | C_BLINK ; 	
}

void atar_con_alambre(){
	print("(^.^)-b ... LO ATAMO' CON ALAMBRE ", VIDEO_COLS - 34, VIDEO_FILS -1, C_BG_BLACK | C_FG_LIGHT_GREEN);
	print("^", VIDEO_COLS - 33, VIDEO_FILS -1, C_BG_BLACK | C_FG_LIGHT_GREEN | C_BLINK);
	print("^", VIDEO_COLS - 31, VIDEO_FILS -1, C_BG_BLACK | C_FG_LIGHT_GREEN | C_BLINK);
	while(1){
		print("S", 0, 0, C_BG_MAGENTA);
		print("S", 0, 0, C_BG_CYAN);
	}
}
