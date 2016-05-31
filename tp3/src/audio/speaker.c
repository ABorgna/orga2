#include "../defines.h"
#include "../i386.h"
#include "../interrupts/pit.h"

#include "speaker.h"

// Play sound using built in speaker
void play_sound(uint32_t nFrequence) {
    uint8_t tmp;

    if(!nFrequence) {
        nosound();
        return;
    }

    // Set the PIT to the desired frequency
    setupPIT(2, nFrequence);

    // Enable the PIT-Speaker channel if necessary
    tmp = inb(0x61);
    if (tmp != (tmp | 3)) {
        outb(0x61, tmp | 3);
    }
}

// Disable the speaker
void nosound() {
    uint8_t tmp = inb(0x61) & 0xFC;
    outb(0x61, tmp);
}

// Make a beep
void beep() {
    play_sound(1000);
}

