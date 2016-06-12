; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================
; definicion de rutinas de atencion de interrupciones

%include "imprimir.mac"

BITS 32

sched_tarea_offset:     dd 0x00
sched_tarea_selector:   dw 0x00

;; PIC
extern fin_intr_pic1

;; Sched
extern sched_proximo_indice

;; System clock
extern rtc_isr

;; Audio
extern audio_isr

;; Keyboard
extern keyboard_isr

;; Game
extern game_kill_task
extern game_soy
extern game_donde
extern game_mapear
extern game_show_debug
;;
;; Definición de MACROS
;; -------------------------------------------------------------------------- ;;

global _isr_default
_isr_default:
    pushad
    mov eax, 0xDEADBEEF
    mov eax, 0x0DEFA017
    popad
    iret

%macro ISR 2
global _isr%1

interrupt_msg_%1 db         %2
interrupt_msg_%1_len equ    $ - interrupt_msg_%1

_isr%1:
    pushad
    xchg bx, bx

    mov eax, 0xC01DCAFE
    mov eax, %1

    ; Si no está habilitado, no hace nada
    call game_show_debug

    ; Despedite de tu tarea
    call game_kill_task

    imprimir_texto_mp interrupt_msg_%1, interrupt_msg_%1_len, 0x07, 3, 0
    popad
    iret

%endmacro

%macro ISR_EC 2
global _isr%1

interrupt_msg_%1 db         %2
interrupt_msg_%1_len equ    $ - interrupt_msg_%1

_isr%1:
    add esp, 4
    pushad
    xchg bx, bx

    mov eax, 0xC01DCAFE
    mov eax, %1

    ; Si no está habilitado, no hace nada
    call game_show_debug

    ; Despedite de tu tarea
    call game_kill_task

    imprimir_texto_mp interrupt_msg_%1, interrupt_msg_%1_len, 0x07, 3, 0
    popad
    iret

%endmacro

;;
;; Datos
;; -------------------------------------------------------------------------- ;;
; Scheduler
isrnumero:           dd 0x00000000
isrClock:            db '|/-\'

;;
;; Rutina de atención de las EXCEPCIONES
;; -------------------------------------------------------------------------- ;;
ISR 0, '0'
ISR 1, '1'
ISR 2, '2'
ISR 3, '3'
ISR 4, '4'
ISR 5, '5'
ISR 6, '6'
ISR 7, '7'
ISR_EC 8, '8'
ISR 9, '9'
ISR_EC 10, '10'
ISR_EC 11, '11'
ISR_EC 12, '12'
ISR_EC 13, '13'
ISR_EC 14, '14'
ISR 15, '15'
ISR 16, '16'
ISR_EC 17, '17'
ISR 18, '18'
ISR 19, '19'

;;
;; Rutina de atención del PIT
;; -------------------------------------------------------------------------- ;;
global _isr32
_isr32:
    pushad

    ; Send the EOI to the PIC
    mov al, 0x20
    out 0x20, al

    ; Update the audio player
    call audio_isr

    popad
    iret

;;
;; Rutina de atención del TECLADO
;; -------------------------------------------------------------------------- ;;
global _isr33
_isr33:
    pushad

    ; Send the EOI to the PIC
    mov al, 0x20
    out 0x20, al

    ; Do things
    call keyboard_isr

    popad
    iret

;;
;; Rutina de atención del RTC
;; -------------------------------------------------------------------------- ;;
global _isr40
_isr40:
    pushad

    ; Send the EOI to PICs 1 & 2
    mov al, 0x20
    out 0x20, al
    out 0xA0, al

    ; System clock
    call rtc_isr

    popad
    iret

;;
;; Rutinas de atención de las SYSCALLS
;; -------------------------------------------------------------------------- ;;

%define SYSCALL_DONDE  0x124
%define SYSCALL_SOY    0xA6A
%define SYSCALL_MAPEAR 0xFF3

%define VIRUS_ROJO 0x841
%define VIRUS_AZUL 0x325

global _isr0x66
_isr0x66:
    pushad

    cmp eax, SYSCALL_DONDE
    jne .not_donde
        push ebx
        call game_donde
        add esp, 4
        jmp .end
    .not_donde:

    cmp eax, SYSCALL_SOY
    jne .not_soy
        push ebx
        call game_soy
        add esp, 4
        jmp .end
    .not_soy:

    cmp eax, SYSCALL_MAPEAR
    jne .not_mapear
        push ecx
        push ebx
        call game_mapear
        add esp, 8
        jmp .end
    .not_mapear:

    ; Syscall invalido

    call game_show_debug
    call game_kill_task

    .end:
    popad
    iret

;; Funciones Auxiliares
;; -------------------------------------------------------------------------- ;;
proximo_reloj:
        pushad
        inc DWORD [isrnumero]
        mov ebx, [isrnumero]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock
                imprimir_texto_mp ebx, 1, 0x0f, 49, 79
                popad
        ret
