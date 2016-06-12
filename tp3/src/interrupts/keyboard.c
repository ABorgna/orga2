#include "keyboard.h"

#include "../screen.h"
#include "../i386.h"
#include "pic.h"
#include "../audio/audioplayer.h"
#include "../game.h"

void keyboard_player_keys(unsigned char key);
void keyboard_sound_keys(unsigned char key);

void keyboard_isr(){
    unsigned char input = inb(0x60);
    unsigned char key = status2ASCII(input);

    print_hex(input, 2, 70, 0, C_FG_LIGHT_MAGENTA);

    //Debugger on/off
    if (key == 'Y'){
        dbg_enabled = ~dbg_enabled;
        print_hex(dbg_enabled, 1, 0, 0, C_BG_BLACK | C_FG_GREEN);
        game_hide_debug();
    }

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
    switch(key){
        case 'W': game_mover_cursor(player_A, ARB); break;
        case 'S': game_mover_cursor(player_A, ABA); break;
        case 'A': game_mover_cursor(player_A, IZQ); break;
        case 'D': game_mover_cursor(player_A, DER); break;
        case '^': game_mover_cursor(player_B, ARB); break;
        case 'v': game_mover_cursor(player_B, ABA); break;
        case '<': game_mover_cursor(player_B, IZQ); break;
        case '>': game_mover_cursor(player_B, DER); break;
    }
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
            output = 'S';
            break;
        case 0x1E:
            output = 'A';
            break;
        case 0x20:
            output = 'D';
            break;
        case 0x11:
            output = 'W';
            break;
        case 0x2A:
            output = 1; //shift l
            break;
        //Debugger
        case 0x15:
            output = 'Y';
            break;
        //Player 2
        case 0x50:
            output = 'v';
            break;
        case 0x4B:
            output = '<';
            break;
        case 0x4D:
            output = '>';
            break;
        case 0x48:
            output = '^';
            break;
        case 0x59:
            output = 2; //shift r
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
