
#ifndef __KEYBOARD_H__
#define __KEYBOARD_H__

void keyboard_isr();
void keyboard_init();
unsigned char status2ASCII(unsigned char input);

#endif // __KEYBOARD_H__