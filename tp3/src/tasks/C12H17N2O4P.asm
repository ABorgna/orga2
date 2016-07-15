
; *---------------------------------*
; | C12H17N2O4P
; | aka Honguitos Mágicos
; |
; | Planta esporas en el mapa
; | Cuando una se activa copia el código del padre.
; |
; | Además mantiene una lista de conocidos,
; | y cada cierto tiempo checkea que no los hayan modificado.
; |
; | Ideas:
; |     - Still alive counter
; |     - Algoritmo de exploración ?
; |
; *---------------------------------*

%define OFFSET_START 0x08000000
%define OFFSET_SPORE (OFFSET_START + 0xE48)

%define SYSCALL_DONDE  0x124
%define SYSCALL_SOY    0xA6A
%define SYSCALL_MAPEAR 0xFF3

%define VIRUS_ROJO 0x841
%define VIRUS_AZUL 0x325

%macro PADDING 1
    ; Padding con NOPs de 1 byte hasta la posición %1
    times (%1-$) db 0x90
%endmacro

%macro CHECKSUM 2
    ; Calcular un checksum usando xor desde [%1] hasta [%2]
    ; Resultado en eax, modifica ebx y ecx
    mov ecx, (%2 - %1)
    xor eax, eax
    .loop_%1_%2:
        xor eax, [ecx + %1 - 1]
    loop .loop_%1_%2

%endmacro

org OFFSET_START
start:

    ; *---------------------------------*
    ; | Hello world
    ; |
    ; | Pedir mi posición y pasar al main loop
    ; *---------------------------------*

    ; Movemos el esp a donde no moleste
    mov esp, (OFFSET_SPORE - 1)

    ; whoami
    ; Evitamos que quede el código de la syscall a la vista
    ; Guardamos en (POS_X, POS_Y)
    mov eax, (SYSCALL_DONDE - 1)
    inc eax
    mov ebx, POS_X
    nop
    int 0x66

    ; *---------------------------------*
    ; | Main loop
    ; *---------------------------------*

    main_loop:

        ; Mapear algo
        .mappear_siguiente:
            ; Guardamos x,y mapeados en dl,dh

            ; TODO: decidir a quien mapear

            ; Mapear la posición calculada
            ; Evitamos que quede el código de la syscall a la vista
            mov eax, (SYSCALL_MAPEAR - 1)
            inc eax
            movzx ebx, dl
            movzx ecx, dh
            int 0x66

        ; Copiamos la espora
        .disperar_espora:
            ; TODO: checkear que no sobreescribamos a alguno nuestro
            ; (checksum)

            ; Llenamos la primer parte de nops
            mov edi, OFFSET_START + 0x1000)
            mov ecx, (OFFSET_SPORE - OFFSET_START)
            mov al, 0x90 ; nop
            rep stosb

            ; Copiamos desde la espora en adelante
            mov esi, OFFSET_SPORE
            mov edi, (OFFSET_SPORE + 0x1000)
            mov ecx, (0x1000 - OFFSET_SPORE)
            rep movsb

            ; Le guardamos su posición en sus variables
            ; (quedó guardada en dh:dl)
            mov [POS_X + 0x1000], dx

            ; Copiamos nuestra posición también
            mov ax, [POS_X]
            mov [PADRE_X + 0x1000], ax

        jmp main_loop
    end_loop:

    ; *---------------------------------*
    ; | Throw the data at the end
    ; *---------------------------------*
    PADDING OFFSET_SPORE
    org OFFSET_SPORE

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
        movzx ebx, byte [PADRE_X]
        movzx ecx, byte [PADRE_Y]
        int 0x66

        ; Ya lo tenemos
        ; copiamos tod0 su contenido hasta OFFSET_SPORE
        mov esi, (OFFSET_START + 0x1000)
        mov edi, OFFSET_START
        mov ecx, (OFFSET_SPORE - OFFSET_START)
        rep movsb

        ; Ya estamos listos,
        ; vamos al loop principal
        jmp main_loop
    end_spore

    ; *---------------------------------*
    ; | Tabla de conocidos
    ; *---------------------------------*

    tabla:
        ; TODO
    end_tabla:

    ; *---------------------------------*
    ; | Variables
    ; *---------------------------------*

    vars:
        POS_X: db 0
        POS_Y: db 0
        PADRE_X: db 0
        PADRE_Y: db 0
    end_vars:

    ; *---------------------------------*
    ; | Llenar lo que sobra de NOPs
    ; *---------------------------------*

    PADDING pre_end
    pre_end:
    jmp start

org (OFFSET_START + 0x1000)
end:

