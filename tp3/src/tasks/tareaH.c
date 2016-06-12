/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#include "../colors.h"
#include "../defines.h"
#include "../i386.h"
#include "syscall.h"

void task() {
    while(1) {
        __asm __volatile("mov $2, %%eax":::"eax");
    }
}
