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

    rtc_seed_prng(0);

    if(interruptsEnabled) {
        enable_interrupts();
    }
}

void rtc_seed_prng(bool interruptsEnabled) {
    // Seed the prng with a ````````random```````` seed (not)
    char sec, min, hour;
    int seed = rdtsc();

    // Prevent interruptions while working
    disable_interrupts();

    // Read the current time
    outb(RTC_CMD, RTC_MASK_NMI | RTC_SECONDS);
    sec = inb(RTC_DATA);

    outb(RTC_CMD, RTC_MASK_NMI | RTC_MINUTES);
    min = inb(RTC_DATA);

    outb(RTC_CMD, RTC_MASK_NMI | RTC_HOURS);
    hour = inb(RTC_DATA);

    seed ^= (uint32_t) sec;
    seed ^= (uint32_t) min << 8;
    seed ^= (uint32_t) hour << 16;

    srand(seed);
    rand(1);

    if(interruptsEnabled) {
        enable_interrupts();
    }
}

void rtc_isr() {
    // Read RTC_C to ack the interruption
    outb(RTC_CMD, RTC_MASK_NMI | RTC_C);
    inb(RTC_DATA);

    game_tick();
}

