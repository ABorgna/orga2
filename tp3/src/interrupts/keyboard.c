#include "keyboard.h"

#include "../screen.h"
#include "../i386.h"
#include "pic.h"
#include "../audio/audioplayer.h"
#include "../game.h"

void keyboard_player_keys(unsigned char key);
void keyboard_sound_keys(unsigned char key);
void keyboard_restart_msg_keys(unsigned char key);
void keyboard_debugger_keys(unsigned char key);

void keyboard_isr(){
    unsigned char input = inb(0x60);
    unsigned char key = status2ASCII(input);

    print_hex(input, 2, 70, 0, C_FG_LIGHT_MAGENTA);

    // Si se esta mostrando el mensaje de reiniciar, no hacer nada mas
    if(game_restart_msg_shown()) {
        keyboard_restart_msg_keys(key);
        return;
    }

    // Si se está mostrando el debugger, no hacer nada mas
    if (game_debugger_displayed()){
        keyboard_debugger_keys(key);
        return;
    }

    // Mensaje de reiniciar
    if(key == 3) { // Esc
        game_show_restart_msg();
    }

    // Debugger on
    if (key == 'Y'){
        game_enable_debugger(true);
    }

    // Otros
    keyboard_sound_keys(key);
    keyboard_player_keys(key);
}

void keyboard_init(){
    // Enable keyboard interrupts
    IRQ_clear_mask(1);
}

void keyboard_restart_msg_keys(unsigned char key) {
    switch (key){
        case 'Y':
            // Reiniciar juego
            game_restart();
            break;
        case 'N':
        case '\n': // Enter
        case 3: // Esc
            game_hide_restart_msg();
            break;
    }
}

void keyboard_debugger_keys(unsigned char key) {
    switch (key){
        case 'Y':
            game_enable_debugger(false);
        case '\n': // Enter
        case 3: // Esc
            // Cerrar el debugger
            game_hide_debug();
            break;
    }
}

void keyboard_player_keys(unsigned char key) {
    if(key >= 32) print_char(key, 79, 0, C_FG_LIGHT_MAGENTA);
    switch(key){
        // Movimiento
        case 'W':
        case ',': // dvorak
            game_mover_cursor(player_A, ARB);
            break;
        case 'S':
        case 'O': // dvorak
            game_mover_cursor(player_A, ABA);
            break;
        case 'A':
            game_mover_cursor(player_A, IZQ);
            break;
        case 'D':
        case 'E': // dvorak
            game_mover_cursor(player_A, DER);
            break;
        case '^':
            game_mover_cursor(player_B, ARB);
            break;
        case 'v':
            game_mover_cursor(player_B, ABA);
            break;
        case '<':
            game_mover_cursor(player_B, IZQ);
            break;
        case '>':
            game_mover_cursor(player_B, DER);
            break;

        // Disparar
        case 1: // shift l
            game_lanzar_inplace(player_A);
            break;
        case 2: // shift r
            game_lanzar_inplace(player_B);
            break;
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
        case 14: // F4
            play_kirby();
            break;
        case 15: // F5
            play_mario();
            break;
        case 16: // F6
            play_megaman();
            break;
        case 17: // F7
            play_pokemon_gsc();
            break;
        case 18: // F8
            play_pokemon_rby();
            break;
        case 19: // F9
            play_sonic();
            break;
        case 20: // F10
            play_superfantasy();
            break;
    }
}

unsigned char status2ASCII(unsigned char input){
    unsigned char output = 0;
    switch (input){
        case 0x01: // Esc
            output = 3;
            break;
        //Player 1
        case 0x11:
            output = 'W';
            break;
        case 0x12:
            output = 'E';
            break;
        case 0x18:
            output = 'O';
            break;
        case 0x1C:
            output = '\n';
            break;
        case 0x1E:
            output = 'A';
            break;
        case 0x1F:
            output = 'S';
            break;
        case 0x20:
            output = 'D';
            break;
        case 0x2A:
            output = 1; //shift l
            break;
        case 0x31:
            output = 'N';
            break;
        case 0x33:
            output = ',';
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
        case 0x36:
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
