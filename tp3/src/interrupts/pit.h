
#ifndef __PIT_H__
#define __PIT_H__

void setupPIT(uint8_t channel, uint32_t hz);
void disablePIT(uint8_t channel);

#endif // __PIT_H__
