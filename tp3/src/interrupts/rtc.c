#include "../defines.h"
#include "../i386.h"
#include "../interrupts/pic.h"

#include "rtc.h"
#include "clock.h"

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
    // Read RTC_C to ack the interruption
    outb(RTC_CMD, RTC_MASK_NMI | RTC_C);
    inb(RTC_DATA);

    updateClock();
}

