/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de las rutinas de atencion de interrupciones
*/

#include "defines.h"
#include "idt.h"
#include "isr.h"

#include "tss.h"

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


void idt_inicializar() {
    asm("xchgw %bx, %bx");
    // Excepciones
    IDT_ENTRY_TRAP(0);
    IDT_ENTRY_TRAP(1);
    IDT_ENTRY_TRAP(2);
    IDT_ENTRY_TRAP(3);
    IDT_ENTRY_TRAP(4);
    IDT_ENTRY_TRAP(5);
    IDT_ENTRY_TRAP(6);
    IDT_ENTRY_TRAP(7);
    IDT_ENTRY_TRAP(8);
    IDT_ENTRY_TRAP(9);
    IDT_ENTRY_TRAP(10);
    IDT_ENTRY_TRAP(11);
    IDT_ENTRY_TRAP(12);
    IDT_ENTRY_TRAP(13);
    IDT_ENTRY_TRAP(14);
    IDT_ENTRY_TRAP(15);
    IDT_ENTRY_TRAP(16);
    IDT_ENTRY_TRAP(17);
    IDT_ENTRY_TRAP(18);
    IDT_ENTRY_TRAP(19);
}

