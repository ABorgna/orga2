#include "../defines.h"
#include "../i386.h"
#include "pic.h"

#include "pit.h"

void initClock(){
    setupPIT(0,1000);

    // Enable PIT 0 interrupts
    IRQ_clear_mask(0);
}

void updateClock(){
    // Called every 1ms (roughly)
}

void setupPIT(uint8_t channel, uint32_t hz) {
    assert(channel == 0 || channel == 2);

    // Calculate our divisor
    uint32_t divisor = 1193180 / hz;

    // Configure the pit, mode 3 (square wave)
    outb(0x43, 0x36 | (channel << 6));

    // Send the 16b count to the corresponding port
    outb(0x40 + channel, (uint8_t) (divisor & 0xFF));
    outb(0x40 + channel, (uint8_t) (divisor >> 8));
}
