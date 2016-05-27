/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  funciones del controlador de interrupciones
*/

#ifndef __PIC_H__
#define __PIC_H__

#define PIC1_CMD 0x20
#define PIC1_DATA 0x21
#define PIC2_CMD 0xA0
#define PIC2_DATA 0xA1

void resetear_pic(void);
void habilitar_pic();
void deshabilitar_pic();
void IRQ_set_mask(unsigned char IRQline);
void IRQ_clear_mask(unsigned char IRQline);

static __inline __attribute__((always_inline)) void fin_intr_pic1(void) {
    outb(0x20, 0x20);
}
static __inline __attribute__((always_inline)) void fin_intr_pic2(void) {
    outb(PIC1_CMD, 0x20); outb(PIC2_CMD, 0x20);
}


#endif	/* !__PIC_H__ */
