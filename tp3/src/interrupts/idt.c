    /* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de las rutinas de atencion de interrupciones
*/

#include "../defines.h"
#include "idt.h"
#include "isr.h"

#include "../tss.h"

idt_entry idt[255] = { };

idt_descriptor IDT_DESC = {
    sizeof(idt) - 1,
    (unsigned int) &idt
};

/*
    La siguiente es una macro de EJEMPLO para ayudar a armar entradas de
    interrupciones. Para usar, descomentar y completar CORRECTAMENTE los
    atributos y el registro de segmento. Invocarla desde idt_inicializar() de
    la siguiene manera:

    void idt_inicializar() {
        IDT_ENTRY(0);
        ...
        IDT_ENTRY(19);

        ...
    }
*/

#define IDT_ENTRY_TRAP(numero)                                              \
    idt[numero].offset_0_15 = (unsigned short)                              \
        ((unsigned int)(&_isr##numero) & (unsigned int) 0xFFFF);            \
    idt[numero].segsel = (unsigned short) GDT_CODE_0_DESC;                  \
    idt[numero].attr = (unsigned short) 0x8F00;                             \
    idt[numero].offset_16_31 = (unsigned short)                             \
        ((unsigned int)(&_isr##numero) >> 16 & (unsigned int) 0xFFFF);

#define IDT_ENTRY_INTERRUPT(numero)                                         \
    idt[numero].offset_0_15 = (unsigned short)                              \
        ((unsigned int)(&_isr##numero) & (unsigned int) 0xFFFF);            \
idt[numero].segsel = (unsigned short) GDT_CODE_0_DESC;                      \
    idt[numero].attr = (unsigned short) 0x8E00;                             \
    idt[numero].offset_16_31 = (unsigned short)                             \
        ((unsigned int)(&_isr##numero) >> 16 & (unsigned int) 0xFFFF);

#define IDT_ENTRY_INTERRUPT_DEFAULT(numero)                                 \
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

    for(i = 20; i < 32; i++) {IDT_ENTRY_INTERRUPT_DEFAULT(i);}

    IDT_ENTRY_INTERRUPT(32);
    IDT_ENTRY_INTERRUPT(33);

    for(i = 34; i < 256; i++) {IDT_ENTRY_INTERRUPT_DEFAULT(i);}
}

