#include "keyboard.h"
#include "../screen.h"
#include "../i386.h"
#include "pic.h"

unsigned int player1 = 0;
unsigned int player2 = 0;

void keyboard_isr(){
	unsigned char input = inb(0x60);
	unsigned char output = status2ASCII(input);
	if(output >= 32) print_char(output, 79, 0, C_FG_LIGHT_MAGENTA | C_BLINK);
	print_int(player1, 11, 0, C_FG_RED, 10);
	print_int(player2, 11, 2, C_FG_LIGHT_BLUE, 10);
}

void keyboard_init(){
	// Enable keyboard interrupts
	IRQ_clear_mask(1);
}

unsigned char status2ASCII(unsigned char input){
	unsigned char output = 0;
	switch (input){
		//Player 1
		case 0x1F:
			output = 'S'; player1++;
			break;
		case 0x1E:
			output = 'A'; player1++;
			break;
		case 0x20:
			output = 'D'; player1++;
			break;
		case 0x11:
			output = 'W'; player1++;
			break;
		case 0x2A:
			output = 1; //shift l 
			player1++;
			break;
		//Debugger
		case 0x15:
			output = 'Y';
			break;
		//Player 2
		case 0x50:
			output = 'v'; player2++;
			break;
		case 0x4B:
			output = '<'; player2++;
			break;
		case 0x4D:
			output = '>'; player2++;
			break;
		case 0x48:
			output = '^'; player2++;
			break;
		case 0x59:
			output = 2; //shift r
			player2++;		
			break;
	}
	return output;
}