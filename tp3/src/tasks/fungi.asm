
; *---------------------------------*
; |
; | Fungi
; | aka honguitos mágicos
; |
; | Planta esporas en el mapa
; | Cuando una se activa copia el código del padre.
; |
; | Guarda las celdas exploradas y los aliados conocidos en un bitmap.
; | Cada cierto tiempo checkea alguno de sus aliados para ver si lo conquistó
; | el otro jugador, y mira su tabla de exploradas.
; |
; | La exploración se realiza en pasos de tamaño dependiente de la posición,
; | siempre una cantidad coprima a 80 * 44 para que
; | termine recorriendo tod0 el mapa.
; | Se hace una serie de intentos para buscar casilleros sin explorar.
; |
; | Además, una tarea iniciada por el jugador siempre explora el casillero
; | de abajo primero.
; |
; | Ideas:
; |     - Generation counter + tabla de conocidos
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

%define CHECKSUM_ROJO 0x6C8BAF61
%define CHECKSUM_AZUL 0x67E4CB61

; Descomentar esto para activar el modo de testeo de checksum
; Apenas inicia la tarea calcula todos los valores, y va tirando breakpoints
; Ver checksum_tester
;%define TEST_CHECKSUM_MODE

%define MY_COLOR 0
%define MY_CHECKSUM 0
%ifdef TASK_A
    %define MY_COLOR VIRUS_ROJO
    %define MY_CHECKSUM CHECKSUM_ROJO
%elifdef TASK_B
    %define MY_COLOR VIRUS_AZUL
    %define MY_CHECKSUM CHECKSUM_AZUL
%else
    %error "Definir TASK_A o TASK_B con -dTASK_x"
%endif


%macro PADDING 1
    ; Padding con NOPs de 1 byte hasta la posición %1
    times (%1-OFFSET_START-($-$$)) db 0x90
%endmacro

%macro CHECKSUM 2
    ; Calcular un checksum usando xor desde [%1] hasta [%2]
    ; Resultado en eax, modifica ecx
    mov ecx, ((%2 - %1)/4)
    xor eax, eax
    .loop:
        ;crc32 eax, byte [ecx + %1 - 1]
        xor eax, [ecx * 4 + %1 - 4]
    loop .loop

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
    ; | Pedir mi posición, decir quién soy y pasar al main loop
    ; *---------------------------------*

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

    ; Calculamos nuestra posición lineal
    movzx edx, word [var(POS_X)]
    DX_TO_LINEAR
    mov [var(POS_LINEAR)], dx

    ; Nos marcamos como aliados en nuestro mapa
    mov eax, edx
    mov ebx, edx
    shr eax, 2
    and ebx, 3
    shl ebx, 1
    bts [var(mapa) + eax], ebx
    inc ebx
    bts [var(mapa) + eax], ebx

    ; Soy yo!
    mov eax, (SYSCALL_SOY - 1)
    inc eax
    mov ebx, MY_COLOR
    nop
    int 0x66

    ; Siempre exploramos el casillero de abajo al ser
    ; iniciados por el jugador
    mov bx, [var(POS_X)]
    mov [var(MAPPED_X)], bx

    mov eax, 80
    jmp mapear_siguiente

    ; *---------------------------------*
    ; | Entrada de las esporas
    ; *---------------------------------*

    start_spore:

        ; Empezar a recorrer a partir de mi posicion
        movzx edx, word [var(POS_X)]
        mov [var(MAPPED_X)], dx

        ; Inicializar cosas
        mov byte [var(MAP_COUNTER)], 0

        ; Precalcular nuestra posición lineal
        DX_TO_LINEAR
        mov [var(POS_LINEAR)], dx

        ; Marcarle a mi padre que estoy viva (y a mi misma)
        mov eax, edx
        mov ebx, edx
        shr eax, 2
        and ebx, 3
        shl ebx, 1
        bts [var(mapa) + eax], ebx
        bts [var(mapa) + 0x1000 + eax], ebx
        inc ebx
        bts [var(mapa) + eax], ebx
        bts [var(mapa) + 0x1000 + eax], ebx

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
            and eax, 0xf
            movzx eax, byte [eax + var(STEPS)]

        ; Mapear algo
        mapear_siguiente:
            ; Calcular la nueva posición a explorar
            ; Recorremos de a eax pasos,
            ; buscando una posición sin explorar en el mapa
            ; si después de 251 iteraciónes nos quedamos con
            ; esa posición, esté explorada o no
            ; (esto sirve para cuando ya exploramos tod0 el mapa)
            ;
            ; También, cada 8 turnos, visitamos el próximo aliado
            ; a partir de donde estamos recorriendo.
            ; (Así lo reconquistamos si apareció el otro jugador)
            movzx edx, word [var(MAPPED_X)]
            DX_TO_LINEAR

            inc word [var(MAP_COUNTER)]
            test word [var(MAP_COUNTER)], 7

            jz .visitar_aliado

                mov ecx, 251
                .loop_pasos:

                    ; Incrementar la posición
                    cmp eax, edx
                    jle .fin_check_underflow
                        ; Evitar que se vaya a una cuenta negativa
                        add edx, 80*44
                    .fin_check_underflow:
                    add edx, eax

                    ; Checkear overflow
                    cmp edx, 80*44
                    jl .end_check_overflow
                        sub edx, 80*44
                    .end_check_overflow:

                    ; Checkear si está explorada
                    mov ebx, edx
                    mov edi, edx
                    shr ebx, 2
                    and edi, 3
                    shl edi, 1
                    bt [var(mapa) + ebx], edi
                    jnc .end_loop_pasos

                loop .loop_pasos
                .end_loop_pasos:

                ; Limpiamos esi para marcar que no visitamos un aliado
                xor esi, esi

                jmp .end_visitar_aliado

            .visitar_aliado:

                ; Nuestra posición lineal en edi
                movzx edi, word [var(POS_LINEAR)]

                ; Buscar el próximo aliado
                mov ecx, 80*44 ; Podemos llegar a recorrer tod0 el mapa buscando
                .loop_buscar_aliado:
                    ; Incrementar la posición
                    inc edx

                    ; No revisarnos a nosotros mismos
                    cmp edx, edi
                    je .continue_loop_buscar_aliado

                    ; Checkear overflow
                    cmp edx, 80*44
                    jl .end_check_overflow_aliado
                        sub edx, 80*44
                    .end_check_overflow_aliado:

                    ; Checkear si es un aliado
                    mov ebx, edx
                    mov edi, edx
                    shr ebx, 2
                    and edi, 3
                    shl edi, 1
                    inc edi
                    bt [var(mapa) + ebx], edi
                    jc .end_loop_buscar_aliado

                    .continue_loop_buscar_aliado:
                loop .loop_buscar_aliado
                .end_loop_buscar_aliado:

                ; Seteamos esi para marcar que visitamos un aliado
                xor esi, esi
                inc esi

            .end_visitar_aliado:

            mov edi, edx
            DX_TO_XY
            ; la posicion lineal queda en edi

            ; Si esi != 0, estamos visitando un aliado
            ; y no debemos guardar su posición
            cmp esi, 0
            jnz .end_guardar_posicion
                mov [var(MAPPED_X)], dx
            .end_guardar_posicion:

            ; No mapearnos a nosotros mismos...
            cmp dx, [var(POS_X)]
            je main_loop

            ; Mapear la posición calculada
            ; Evitamos que quede el código de la syscall a la vista
            mov eax, (SYSCALL_MAPEAR - 1)
            inc eax
            movzx ebx, dl
            movzx ecx, dh
            int 0x66

            ; x,y mapeados quedan en dl,dh
            ; la direccion lineal mapeada queda en edi

        ; Una vez mapeada la nueva posición, tenemos tres casos
        ; - No es nuestro
        ;   Copiamos la espora y la marcamos en nuestro mapa
        ; - Es una espora
        ;   Si el padre no estaba en nuestro mapa, lo agregamos como aliado
        ;   Si no está corriendo, le cambiamos el padre por nosotros
        ; - Es un aliado
        ;   Mergeamos los mapas,
        ;   muerto > aliado > espora > nada
        conquistar_mapeado:

            ; Marcamos la posición como explorada
            mov eax, edi
            mov ebx, edi
            shr eax, 2
            and ebx, 3
            shl ebx, 1
            bts [var(mapa) + eax], ebx

            ; Si no está conquistado, no es nuestro
            call is_conquered
            cmp eax,0
            jz dispersar_espora

            ; Si no está conquistado
            call get_type
            cmp eax,0
            je dispersar_espora ; corrupto (lo modificaron)
            cmp eax, 1
            je leer_de_aliado
            jmp leer_de_espora

        ; Copiamos la espora
        dispersar_espora:
            ; La posición XY mapeada está en dl,dh
            ; la direccion lineal mapeada está en edi

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

            ; Copiamos nuestra posición también
            mov ax, [var(POS_X)]
            mov [var(PADRE_X) + 0x1000], ax

            ; No está activa
            mov byte [var(ACTIVA) + 0x1000], 0

            jmp main_loop

        leer_de_espora:
            ; La posición XY mapeada está en dl,dh
            ; la direccion lineal mapeada está en edi

            ; Guardamos el padre como un aliado
            ; TODO: ver como funciona con esto desactivado,
            ;       así evitas estar reviviendo cadáveres
            movzx edx, word [var(PADRE_X) + 0x1000]
            DX_TO_LINEAR
            mov eax, edx
            mov ebx, edx
            shr eax, 2
            and ebx, 3
            shl ebx, 1
            bts [var(mapa) + eax], ebx
            inc ebx
            bts [var(mapa) + eax], ebx

            ; Setearme como padre si no está activa
            test byte [var(ACTIVA) + 0x1000], 1
            jnz .end_cambiar_padre
                mov ax, [var(POS_X)]
                mov [var(PADRE_X) + 0x1000], ax
            .end_cambiar_padre:

            jmp main_loop

        leer_de_aliado:
            ; La posición XY mapeada está en dl,dh
            ; la direccion lineal mapeada está en edi

            ; Combinamos los puntos explorados por ambos
            mov ecx, ((end_mapa - mapa)/4)
            .loop:
                mov eax, [ecx * 4 + var(mapa) - 4]
                or eax, [ecx * 4 + var(mapa) + 0x1000 - 4]
                mov [ecx * 4 + var(mapa) - 4], eax
                mov [ecx * 4 + var(mapa) + 0x1000 - 4], eax
            loop .loop

            jmp main_loop

    end_loop:

    ; *---------------------------------*
    ; | Funciones
    ; *---------------------------------*

    ; Checkea si la región mapeada fue conquistada, puede haber germinado o no
    ; Devuelve 0 (false) o 1 (true) en eax
    is_conquered:
        CHECKSUM (var(spore)+0x1000), (var(end_spore)+0x1000)

        cmp eax, [var(CHECKSUM_CONQUERED)]
        sete al
        movzx eax, al

        ; Normalmente comentada, calcula los checksums
        ; y tira breakpoints para verlos
        ; (no se comenta acá sino adentro mismo de la función,
        ; así no cambia las referencias a las variables)
        call checksum_tester

        ret

    ; Checkea el tipo de la región mapeada. Devuelve en eax
    ; 0 - inválido/corrupto
    ; 1 - aliado
    ; 2 - espora
    ; Hay que checkear primero is_conquered
    get_type:
        CHECKSUM (var(start)+0x1000), (var(end_loop)+0x1000)

        cmp al, [var(CHECKSUM_EMPTY)]
        je .is_spore

            cmp al, [var(CHECKSUM_ALIED)]
            sete al
            movzx eax, al
            ret

        .is_spore:
            mov eax, 2
            ret

    ; *---------------------------------*
    ; | Constants
    ; *---------------------------------*

    ; La exploración se realiza en pasos de tamaño STEPS[POS_X % 16]
    ; Notar que los numeros son coprimos con 80x44 = 2^6 * 5 * 11
    STEPS: db 7,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71

    ; Checksums
    ; Hay que recalcularlos si cambia el código
    CHECKSUM_CONQUERED: dd 0x86E1D95F ; Checksum de la función spore
    CHECKSUM_ALIED: dd MY_CHECKSUM ; Checksum de la parte baja del código
    CHECKSUM_EMPTY: dd 0 ; Checksum de la parte baja de una espora (todos NOPs)

    ; *---------------------------------*
    ; | Mapa con las exploraciones
    ; *---------------------------------*

    ; Array de valores de 2b
    ; 00 : sin explorar
    ; 01 : espora
    ; 11 : aliado
    mapa:
        times (80*44/4) db 0 ; 2b por celda, 880 B
    end_mapa:

    ; *---------------------------------*
    ; | Tabla de conocidos (TODO)
    ; | array ordenado con nuestros aliados conocidos,
    ; | y su número de generación
    ; *---------------------------------*

    tabla_len: db 0
    tabla:
        times 32 dw 0 ; Reservamos 32 lugares, 256 B
    end_tabla:

    ; *---------------------------------*
    ; | Otras variables
    ; *---------------------------------*
    internal_vars:
        MAPPED_X: db 0
        MAPPED_Y: db 0

        MAP_COUNTER: dw 0

        POS_LINEAR: dw 0
    end_internal_vars:

    ; *---------------------------------*
    ; | Funcion especial para calcular los checksums
    ; | se puede comentar en la versión final
    ; |
    ; | La función se autoinmola al terminar :)
    ; *---------------------------------*

    checksum_tester:
        ; Comentar para testear
        %ifndef TEST_CHECKSUM_MODE
            ret
        %endif

        ; Calcular nuestros checksums
        xchg bx,bx
        mov eax, 0xDEADCAFE

        label_0000:
            CHECKSUM var(spore), var(end_spore)
            xchg bx,bx
            ; CHECKSUM_CONQUERED en eax

        label_0001:
            CHECKSUM var(start), var(end_loop)
            xchg bx,bx
            ; CHECKSUM_ALIED en eax

        label_0002:
            ; Fillearnos de 0s
            mov edi, var(start)
            mov ecx, (var(end_loop) - var(start))
            mov al, 0x90 ; nop
            rep stosb

            CHECKSUM var(start), var(end_loop)
            xchg bx,bx
            ; CHECKSUM_EMPTY en eax

        ; Destruimos tod0, mejor morir
        mov eax, [0xDEADBEEF]

        ret

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

        ; Hello
        mov byte [var(ACTIVA)], 1

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

        ; Se setea en 1 solo si la tarea está corriendo
        ; (para detectar esporas activas)
        ACTIVA: db 1  ;
    end_vars:

    ; *---------------------------------*
    ; | Llenar lo que sobra de NOPs
    ; *---------------------------------*

    PADDING (OFFSET_END - LAST_JMP_SIZE)
    pre_end:
    jmp start

end:

