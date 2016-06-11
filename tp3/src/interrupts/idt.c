    /* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de las rutinas de atencion de interrupciones
*/

#include "../defines.h"
#include "idt.h"
#include "isr.h"

idt_entry idt[255] = { };

idt_descriptor IDT_DESC = {
    sizeof(idt) - 1,
    (unsigned int) &idt
};

#define IDT_ENTRY(numero, type, dpl)                                        \
    idt[numero].offset_0_15 = (unsigned short)                              \
        ((unsigned int)(&_isr##numero) & (unsigned int) 0xFFFF);            \
    idt[numero].segsel = (unsigned short) GDT_CODE_0_DESC;                  \
    idt[numero].attr = (unsigned short) (0x8000 | (type) | ((dpl)<<13));    \
    idt[numero].offset_16_31 = (unsigned short)                             \
        ((unsigned int)(&_isr##numero) >> 16 & (unsigned int) 0xFFFF);

#define IDT_ENTRY_TRAP(numero) IDT_ENTRY(numero, 0x0F00, 0)
#define IDT_ENTRY_INTERRUPT(numero) IDT_ENTRY(numero, 0x0E00, 0)
#define IDT_ENTRY_TRAP_USER(numero) IDT_ENTRY(numero, 0x0F00, 3)
#define IDT_ENTRY_INTERRUPT_USER(numero) IDT_ENTRY(numero, 0x0E00, 3)

#define IDT_ENTRY_DEFAULT(numero)                                           \
    idt[numero].offset_0_15 = (unsigned short)                              \
        ((unsigned int)(&_isr_default) & (unsigned int) 0xFFFF);            \
idt[numero].segsel = (unsigned short) GDT_CODE_0_DESC;                      \
    idt[numero].attr = (unsigned short) 0x8E00;                             \
    idt[numero].offset_16_31 = (unsigned short)                             \
        ((unsigned int)(&_isr_default) >> 16 & (unsigned int) 0xFFFF);

void idt_inicializar() {
    int i;

    // Excepciones
    IDT_ENTRY_INTERRUPT(0);
    IDT_ENTRY_INTERRUPT(1);
    IDT_ENTRY_INTERRUPT(2);
    IDT_ENTRY_INTERRUPT(3);
    IDT_ENTRY_INTERRUPT(4);
    IDT_ENTRY_INTERRUPT(5);
    IDT_ENTRY_INTERRUPT(6);
    IDT_ENTRY_INTERRUPT(7);
    IDT_ENTRY_INTERRUPT(8);
    IDT_ENTRY_INTERRUPT(9);
    IDT_ENTRY_INTERRUPT(10);
    IDT_ENTRY_INTERRUPT(11);
    IDT_ENTRY_INTERRUPT(12);
    IDT_ENTRY_INTERRUPT(13);
    IDT_ENTRY_INTERRUPT(14);
    IDT_ENTRY_INTERRUPT(15);
    IDT_ENTRY_INTERRUPT(16);
    IDT_ENTRY_INTERRUPT(17);
    IDT_ENTRY_INTERRUPT(18);
    IDT_ENTRY_INTERRUPT(19);

    for(i = 19 + 1; i < 32; i++) {IDT_ENTRY_DEFAULT(i);}

    IDT_ENTRY_INTERRUPT(32); // PIT 0
    IDT_ENTRY_INTERRUPT(33);

    for(i = 33 + 1; i < 40; i++) {IDT_ENTRY_DEFAULT(i);}

    IDT_ENTRY_INTERRUPT(40); // RTC

    for(i = 40 + 1; i < 0x66; i++) {IDT_ENTRY_DEFAULT(i);}

    IDT_ENTRY_INTERRUPT_USER(0x66); // RTC

    for(i = 0x66 + 1; i < 256; i++) {IDT_ENTRY_DEFAULT(i);}
}
