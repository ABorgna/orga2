/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  funciones del controlador de interrupciones
*/

#include "../defines.h"
#include "../i386.h"

#include "pic.h"

void resetear_pic() {
    outb(PIC1_CMD, 0x11); /* IRQs activas x flanco, cascada, y ICW4 */
    outb(PIC1_DATA, 0x20); /* Addr */
    outb(PIC1_DATA, 0x04); /* PIC1 Master, Slave ingresa Int.x IRQ2 */
    outb(PIC1_DATA, 0x01); /* Modo 8086 */
    outb(PIC1_DATA, 0xFF); /* Enmasca todas! */

    outb(PIC2_CMD, 0x11); /* IRQs activas x flanco, cascada, y ICW4 */
    outb(PIC2_DATA, 0x28); /* Addr */
    outb(PIC2_DATA, 0x02); /* PIC2 Slave, ingresa Int x IRQ2 */
    outb(PIC2_DATA, 0x01); /* Modo 8086 */
    outb(PIC2_DATA, 0xFF); /* Enmasca todas! */

    // Enmascarar todas las interrupciones
    outb(PIC1_DATA, ~0x04);
    outb(PIC2_DATA, 0xFF);
}

void habilitar_pic() {
    outb(PIC1_DATA, 0x00);
    outb(PIC2_DATA, 0x00);
}

void deshabilitar_pic() {
    outb(PIC1_DATA, 0xFF);
    outb(PIC2_DATA, 0xFF);
}

void IRQ_set_mask(unsigned char IRQline) {
    uint16_t port;
    uint8_t value;

    if(IRQline < 8) {
        port = PIC1_DATA;
    } else {
        port = PIC2_DATA;
        IRQline -= 8;
    }
    value = inb(port) | (1 << IRQline);
    outb(port, value);
}

void IRQ_clear_mask(unsigned char IRQline) {
    uint16_t port;
    uint8_t value;

    if(IRQline < 8) {
        port = PIC1_DATA;
    } else {
        port = PIC2_DATA;
        IRQline -= 8;
    }
    value = inb(port) & ~(1 << IRQline);
    outb(port, value);
}

