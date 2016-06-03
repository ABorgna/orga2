#include "../defines.h"
#include "../i386.h"
#include "../interrupts/pit.h"

#include "speaker.h"

uint32_t current_freq = 0;

// Play sound using built in speaker
void play_sound(uint32_t frequence) {
    uint8_t tmp;

    if(!frequence) {
        nosound();
        return;
    }

    // Set the PIT to the desired frequency
    if(current_freq != frequence) {
        setupPIT(2, frequence);
    }

    // Enable the PIT-Speaker channel if necessary
    tmp = inb(0x61);
    if (tmp != (tmp | 3)) {
        outb(0x61, tmp | 3);
    }

    current_freq = frequence;
}

// Disable the speaker
void nosound() {
    if(current_freq) {
        disablePIT(2);

        uint8_t tmp = inb(0x61) & 0xFC;
        outb(0x61, tmp);
    }

    current_freq = 0;
}

// Make a beep
void beep() {
    play_sound(1000);
}

