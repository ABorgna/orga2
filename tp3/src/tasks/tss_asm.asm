; ==============================================================================
; TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

BITS 32

global tss_switch_task

offset: dd 0
selector: dw 0

; void tss_switch_task(short descriptor)
tss_switch_task:
    xchg bx,bx
    movzx eax, word [esp+4]
    mov [selector], ax
    jmp far [offset]
    ret

