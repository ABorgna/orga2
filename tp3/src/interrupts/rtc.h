
#ifndef __RTC_H__
#define __RTC_H__

#define RTC_CMD 0x70
#define RTC_DATA 0x71

#define RTC_MASK_NMI 0x80
#define RTC_SECONDS 0x00
#define RTC_MINUTES 0x02
#define RTC_HOURS 0x04
#define RTC_A 0x0A
#define RTC_B 0x0B
#define RTC_C 0x0C
#define RTC_D 0x0D

// Periodic interrupt enable flag
#define RTC_B_PIE 0x40

void init_rtc(bool interruptsEnabled);
void rtc_seed_prng(bool interruptsEnabled);
void rtc_isr();

#endif // __RTC_H__
