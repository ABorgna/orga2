
#ifndef __CLOCK_H__
#define __CLOCK_H__

void initClock();
void updateClock();

void setupPIT(uint8_t channel, uint32_t hz);

#endif // __CLOCK_H__
