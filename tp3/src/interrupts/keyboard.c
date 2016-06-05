#include "keyboard.h"

#include "../screen.h"
#include "../i386.h"
#include "pic.h"
#include "../audio/audioplayer.h"

void keyboard_player_keys(unsigned char key);
void keyboard_sound_keys(unsigned char key);

unsigned int player1 = 0;
unsigned int player2 = 0;

void keyboard_isr(){
    unsigned char input = inb(0x60);
    unsigned char key = status2ASCII(input);

    print_hex(input, 2, 70, 0, C_FG_LIGHT_MAGENTA);

    if(11 <= key && key <= 22) {
        keyboard_sound_keys(key);
    } else {
        keyboard_player_keys(key);
    }
}

void keyboard_init(){
    // Enable keyboard interrupts
    IRQ_clear_mask(1);
}

void keyboard_player_keys(unsigned char key) {
    if(key >= 32) print_char(key, 79, 0, C_FG_LIGHT_MAGENTA);

    print_int(player1, 11, 0, C_FG_RED, 10);
    print_int(player2, 11, 2, C_FG_LIGHT_BLUE, 10);
}

void keyboard_sound_keys(unsigned char key) {
    switch(key) {
        case 11: // F1
            stop_audio();
            break;
        case 12: // F2
            play_pacman();
            break;
        case 13: // F3
            play_spectra();
            break;
    }
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
        // Audio
        case 0x3B:      // F1
            output = 11;
            break;
        case 0x3C:      // F2
            output = 12;
            break;
        case 0x3D:      // F3
            output = 13;
            break;
        case 0x3E:      // F4
            output = 14;
            break;
        case 0x3F:      // F5
            output = 15;
            break;
        case 0x40:      // F6
            output = 16;
            break;
        case 0x41:      // F7
            output = 17;
            break;
        case 0x42:      // F8
            output = 18;
            break;
        case 0x43:      // F9
            output = 19;
            break;
        case 0x44:      // F10
            output = 20;
            break;
        case 0x57:      // F11
            output = 21;
            break;
        case 0x58:      // F12
            output = 22;
            break;
    }
    return output;
}
