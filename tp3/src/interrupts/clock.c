#include "../defines.h"
#include "../i386.h"
#include "pic.h"

#include "clock.h"

void setupPIT(int hz);

void initClock(){
    setupPIT(1024);
}

void updateClock(){
    // TODO
}

void setupPIT(int hz) {
    int divisor = 1193180 / hz;     // Calculate our divisor
    outb(0x43, 0x36);               // Set our command byte 0x36
    outb(0x40, divisor & 0xFF);     // Set low byte of divisor
    outb(0x40, divisor >> 8);       // Set high byte of divisor
    IRQ_clear_mask(0);
}
