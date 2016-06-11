#include "../defines.h"
#include "../i386.h"
#include "../interrupts/pic.h"

#include "../game.h"
#include "../random.h"

#include "rtc.h"

void init_rtc(bool interruptsEnabled){
    // Initialize the RTC at the default freq (1024 Hz)

    // Prevent interruptions while working
    disable_interrupts();

    // Read the current value of register B
    outb(RTC_CMD, RTC_MASK_NMI | RTC_B);
    char prev = inb(RTC_DATA);

    // Set the periodic interrupt enable flag
    outb(RTC_CMD, RTC_MASK_NMI | RTC_B);
    outb(RTC_DATA, prev | RTC_B_PIE);

    // Enable RTC interrupts
    IRQ_clear_mask(8);

    if(interruptsEnabled) {
        enable_interrupts();
    }
}

void rtc_isr() {
    static bool prng_is_seeded = 0;

    // Read RTC_C to ack the interruption
    outb(RTC_CMD, RTC_MASK_NMI | RTC_C);
    inb(RTC_DATA);

    // Seed the pseudo-random number generator
    if(!prng_is_seeded) {
        prng_is_seeded = 1;
        srand(rdtsc());
    }

    game_tick();
}

