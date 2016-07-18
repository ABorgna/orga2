
; *---------------------------------*
; |
; | Planta esporas en el mapa
; | Cuando una se activa copia el código del padre.
; |
; | Además mantiene una lista de conocidos,
; | y cada cierto tiempo checkea que no los hayan modificado.
; |
; | La exploración se realiza en pasos de tamaño dependiente de la posición,
; | siempre una cantidad coprima a 80 * 44 para que
; | termine recorriendo tod0 el mapa.
; |
; | Además, una tarea iniciada por el jugador siempre explora el casillero
; | de la derecha al iniciarse.
; |
; | Falta:
; |     - Llamar a SOY (cuando?)
; |     - No convertir aliados
; |     - Checkear conocidos
; |
; | Ideas:
; |     - Still alive counter
; |
; *---------------------------------*

%define OFFSET_START 0x08000000
%define OFFSET_SPORE (OFFSET_START + 0xE48)
%define OFFSET_END 0x08001000
%define LAST_JMP_SIZE 5 ; TODO: fijarse que no haya cambiado

%define OFFSET_LINKED_START 0x40000000

%define SYSCALL_DONDE  0x124
%define SYSCALL_SOY    0xA6A
%define SYSCALL_MAPEAR 0xFF3

%define VIRUS_ROJO 0x841
%define VIRUS_AZUL 0x325

%define MY_COLOR VIRUS_ROJO

%macro PADDING 1
    ; Padding con NOPs de 1 byte hasta la posición %1
    times (%1-OFFSET_START-($-$$)) db 0x90
%endmacro

%macro CHECKSUM 2
    ; Calcular un checksum usando xor desde [%1] hasta [%2]
    ; Resultado en eax, modifica ecx
    mov ecx, (%2 - %1)
    xor eax, eax
    .loop_%1_%2:
        xor eax, [ecx + %1 - 1]
    loop .loop_%1_%2

%endmacro

%macro DX_TO_LINEAR 0
    ; Convertir la posición guardada como x,y en dl,dh
    ; a la posición lineal x+y*80
    ; Resultado en edx, modifica ecx
    movzx ecx, dh
    movzx edx, dl
    imul ecx, 80
    add edx, ecx

%endmacro

%macro DX_TO_XY 0
    ; Convertir la posición lineal a x:y
    ; Resultado en edx, modifica eax y ecx
    mov eax, edx
    xor edx, edx
    mov ecx, 80*44
    div ecx
    mov eax, edx
    xor edx, edx
    mov ecx, 80
    div ecx
    mov dh, al

%endmacro

; Calcula el offset que la variable
%define var(v) ((v)-OFFSET_LINKED_START+OFFSET_START)

section .text

start:

    ; *---------------------------------*
    ; | Hello world
    ; |
    ; | Pedir mi posición y pasar al main loop
    ; *---------------------------------*

    xchg bx,bx

    ; Movemos el esp a donde no moleste
    mov esp, (OFFSET_SPORE - 1)

    ; whoami
    ; Evitamos que quede el código de la syscall a la vista
    ; Guardamos en (POS_X, POS_Y)
    mov eax, (SYSCALL_DONDE - 1)
    inc eax
    mov ebx, var(POS_X)
    nop
    int 0x66
    ; Hay que convertir de shorts a chars
    mov ax, [var(PADRE_X)]
    mov [var(POS_Y)], ax

    ; Soy yo!
    mov eax, (SYSCALL_SOY - 1)
    inc eax
    mov ebx, MY_COLOR
    nop
    int 0x66

    ; Siempre exploramos el casillero de la derecha al ser
    ; iniciados por el jugador
    mov bx, [var(POS_X)]
    mov [var(MAPPED_X)], bx

    xor eax, eax
    inc eax
    jmp mapear_siguiente

    ; *---------------------------------*
    ; | Entrada de las esporas
    ; *---------------------------------*

    start_spore:

        ; Soy yo!
        mov eax, (SYSCALL_SOY - 1)
        inc eax
        mov ebx, MY_COLOR
        nop
        int 0x66

    ; *---------------------------------*
    ; | Main loop
    ; *---------------------------------*

    main_loop:

        ; Decidir cuantos pasos adelante explorar
        pasos_a_explorar:
            movzx eax, byte [var(POS_X)]
            and eax, 0x3
            movzx eax, byte [eax + var(STEPS)]

        ; Mapear algo
        mapear_siguiente:
            ; Calcular la nueva posición a partir de
            ; los pasos que vamos a dar (en eax)
            movzx edx, word [var(MAPPED_X)]
            DX_TO_LINEAR
            cmp eax, edx
            jle .fin_check_underflow
                ; Evitar que se vaya a una cuenta negativa
                add edx, 80*44
            .fin_check_underflow:
            add edx, eax
            DX_TO_XY

            ; Mapear la posición calculada
            ; Evitamos que quede el código de la syscall a la vista
            mov eax, (SYSCALL_MAPEAR - 1)
            inc eax
            movzx ebx, dl
            movzx ecx, dh
            int 0x66

            mov [var(MAPPED_X)], dx
            ; x,y mapeados quedan en dl,dh

        ; Copiamos la espora
        dispersar_espora:
            ; La posición XY mapeada está en dl,dh

            ; TODO: checkear que no sobreescribamos a alguno nuestro
            ; (checksum)

            ; Llenamos la primer parte de nops
            mov edi, (OFFSET_START + 0x1000)
            mov ecx, (OFFSET_SPORE - OFFSET_START)
            mov al, 0x90 ; nop
            rep stosb

            ; Copiamos desde la espora en adelante
            mov esi, OFFSET_SPORE
            mov edi, (OFFSET_SPORE + 0x1000)
            mov ecx, (0x1000 - (OFFSET_SPORE - OFFSET_START))
            rep movsb

            ; Le guardamos su posición en sus variables
            ; (quedó guardada en dh:dl)
            mov [var(POS_X) + 0x1000], dx
            mov [var(MAPPED_X) + 0x1000], dx

            ; Copiamos nuestra posición también
            mov ax, [var(POS_X)]
            mov [var(PADRE_X) + 0x1000], ax

        jmp main_loop
    end_loop:

    ; *---------------------------------*
    ; | Constants
    ; *---------------------------------*

    ; La exploración se realiza en pasos de tamaño STEPS[POS_X % 8]
    ; Notar que los numeros son coprimos con 80x44 = 2^6 * 5 * 11
    STEPS: db 7,13,17,19,23,29,31,37

    ; *---------------------------------*
    ; | Tabla de conocidos
    ; *---------------------------------*

    tabla:
        ; TODO
    end_tabla:

    ; *---------------------------------*
    ; | Las cosas que se copian con las esporas
    ; | van a partir de OFFSET_SPORE
    ; *---------------------------------*
    PADDING OFFSET_SPORE

    ; *---------------------------------*
    ; | Spore
    ; |
    ; | Tiene su posición XY, y la de su padre.
    ; | Cuando se activa copia el código del padre
    ; | y su tabla de conocidos.
    ; *---------------------------------*

    spore:
        ; I'm alive!

        ; Movemos el esp a donde no moleste
        mov esp, (OFFSET_SPORE - 1)

        ; Mapear mi padre
        mov eax, SYSCALL_MAPEAR
        movzx ebx, byte [var(PADRE_X)]
        movzx ecx, byte [var(PADRE_Y)]
        int 0x66

        ; Ya lo tenemos
        ; copiamos tod0 su contenido hasta OFFSET_SPORE
        mov esi, (OFFSET_START + 0x1000)
        mov edi, OFFSET_START
        mov ecx, (OFFSET_SPORE - OFFSET_START)
        rep movsb

        ; Ya estamos listos,
        ; vamos al loop principal
        jmp start_spore
    end_spore:

    ; *---------------------------------*
    ; | Variables
    ; *---------------------------------*

    vars:
        POS_X: db 0
        POS_Y: db 0
        PADRE_X: db 0
        PADRE_Y: db 0
        MAPPED_X: db 0
        MAPPED_Y: db 0
    end_vars:

    ; *---------------------------------*
    ; | Llenar lo que sobra de NOPs
    ; *---------------------------------*

    PADDING (OFFSET_END - LAST_JMP_SIZE)
    pre_end:
    jmp start ; TODO: fijarse bien

end:

