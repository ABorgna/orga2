; FUNCIONES de C
  extern calloc
  extern malloc
  extern free
  extern strcpy
  extern strlen
  extern tdt_agregar
  extern tdt_borrar
  
; FUNCIONES
  global tdt_crear
  global tdt_recrear
  global tdt_cantidad
  global tdt_agregarBloque
  global tdt_agregarBloques
  global tdt_borrarBloque
  global tdt_borrarBloques
  global tdt_traducir
  global tdt_traducirBloque
  global tdt_traducirBloques
  global tdt_destruir

; /** defines offsets y size **/
  %define TDT_OFFSET_IDENTIFICACION   0
  %define TDT_OFFSET_PRIMERA          8
  %define TDT_OFFSET_CANTIDAD        16
  %define TDT_SIZE                   20
  %define BLOQUE_OFFSET_VALOR         3

section .text

; =====================================
; tdt* tdt_crear(char* identificacion)
tdt_crear:
    ; RDI: id
    ; No stack frame needed (no local vars nor args in stack)

    ; rdi <- strlen(id) + 1 | Calc newId size
    push rdi        ; Aligned stack | [sp+8] = id
    call strlen
    lea rdi, [rax + 1]  ; rdi <- len(id) + 1 = sizeof(*id)

    ; rax <- malloc(rdi) | Allocate newId
    call malloc

    ; rax <- newId | Copy id(rsi) contents to newId(rax)
    pop rsi
    push rax        ; Aligned stack | [sp+8] = newId
    mov rdi, rax
    call strcpy

    ; rax <- calloc(1,TDT_SIZE) | Allocate and zero new TDT
    mov rdi, 1
    mov rsi, TDT_SIZE
    call calloc

    ; rax[IDENTIFICACION] = newId(r15)
    pop rdi
    mov [rax], rdi

    ret

; =====================================
; void tdt_recrear(tdt** tabla, char* identificacion)
tdt_recrear:
    ; RDI: &tabla
    ; RSI: newId
    ; No stack frame needed (no local vars nor args in stack)
    push r15
    push r14
    sub rsp, 8        ; Aligned stack
    mov r15, rdi    ; r15 <- &tabla

    ; rdi <- newId ? newId : tabla->id
    cmp rsi, 0
    cmovz rsi, [r15] ; rsi <- tabla
    cmovz rsi, [rsi] ; rsi <- tabla->id
    mov rdi, rsi

    ; r14 <- newTabla
    call tdt_crear
    mov r14, rax

    ; destruir tabla
    mov rdi, r15
    call tdt_destruir

    ; [r15] <- newTabla
    mov [r15], r14

    add rsp, 8
    pop r14
    pop r15
    ret

; =====================================
; uint32_t tdt_cantidad(tdt* tabla)
tdt_cantidad:
    mov eax, [rdi + TDT_OFFSET_CANTIDAD]
    ret

; =====================================
; void tdt_agregarBloque(tdt* tabla, bloque* b)
tdt_agregarBloque:
    lea rdx, [rsi+BLOQUE_OFFSET_VALOR]    ; rdx <- &(bloque->valor)
    jmp tdt_agregar

; =====================================
; void tdt_agregarBloques(tdt* tabla, bloque** b)
tdt_agregarBloques:

    cmp qword [rsi], 0
    jz .done

    push rdi
    push rsi
    sub rsp, 8  ; Aligned stack
    mov rsi, [rsi]
    call tdt_agregarBloque
    add rsp, 8
    pop rsi
    pop rdi

    add rsi, 8      ; Next block
    jmp tdt_agregarBloques

    .done:
    ret

; =====================================
; void tdt_borrarBloque(tdt* tabla, bloque* b)
tdt_borrarBloque:
    jmp tdt_borrar

; =====================================
; void tdt_borrarBloques(tdt* tabla, bloque** b)
tdt_borrarBloques:
    cmp qword [rsi], 0
    jz .done

    push rdi
    push rsi
    sub rsp, 8  ; Aligned stack
    mov rsi, [rsi]
    call tdt_borrarBloque
    add rsp, 8
    pop rsi
    pop rdi

    add rsi, 8      ; Next block
    jmp tdt_borrarBloques

    .done: ret

; =====================================
; void tdt_traducir(tdt* tabla, uint8_t* clave, uint8_t* valor)
tdt_traducir:
    ; RDI: tabla
    ; ESI: *clave
    ; RDX: valor
    mov esi, [rsi]

    ; rdi <- tN1 or ret
    cmp qword [rdi+TDT_OFFSET_PRIMERA], 0
    jz .done
    mov rdi, [rdi+TDT_OFFSET_PRIMERA]

    ; rdi <- tN2 or ret
    movzx r10, sil
    cmp qword [rdi+r10*8], 0
    jz .done
    mov rdi, [rdi+r10*8]

    ; rdi <- tN3 or ret
    shr esi, 8
    movzx r10, sil
    cmp qword [rdi+r10*8], 0
    jz .done
    mov rdi, [rdi+r10*8]

    ; ret if !valor.valido
    shr esi, 4
    and si, 0x0ff0
    movzx r10, sil
    cmp byte [rdi+r10+15], 0
    jz .done

    ; copy the value
    lea rsi, [rdi+r10]
    mov rdi, rdx
    cld
    movsd
    movsw
    movsb

    .done: ret

; =====================================
; void tdt_traducirBloque(tdt* tabla, bloque* b)
tdt_traducirBloque:
    lea rdx, [rsi+BLOQUE_OFFSET_VALOR]    ; rdx <- &(bloque->valor)
    jmp tdt_traducir
    ret

; =====================================
; void tdt_traducirBloques(tdt* tabla, bloque** b)
tdt_traducirBloques:
    cmp qword [rsi], 0
    jz .done

    push rdi
    push rsi
    sub rsp, 8  ; Aligned stack
    mov rsi, [rsi]
    call tdt_traducirBloque
    add rsp, 8
    pop rsi
    pop rdi

    add rsi, 8      ; Next block
    jmp tdt_traducirBloques

    .done: ret

; =====================================
; void tdt_destruir(tdt** tabla)
tdt_destruir:
    ; RDI -> r15: &tabla
    ; R8:  tabla
    ; R14:  t1
    ; R13: t2
    push r15
    push r14
    push r13    ; Aligned stack
    mov r15, rdi
    mov r8, [rdi]

    mov r14, [r8+TDT_OFFSET_PRIMERA]
    cmp r14, 0
    jz .doneT1

        ; For j in 256..1
        mov rcx, 256
        .t1Loop:
            mov r13, [r14 + rcx * 8 - 8]
            cmp r13, 0
            jz .doneT2
                push rcx

                ; For i in 256..1
                mov rcx, 256
                .t2Loop:
                    ; Free the ith entry of t2
                    push rcx  ; Aligned stack
                    mov rdi, [r13 + rcx * 8 - 8]
                    call free
                    pop rcx
                loop .t2Loop

                ; Free t2
                sub rsp, 8  ; Aligned stack
                mov rdi, r13
                call free

                add rsp, 8
                pop rcx
            .doneT2:
        loop .t1Loop

        ; Free t1
        mov rdi,r14
        call free
    .doneT1:

    ; Free the id string
    mov r8, [r15]
    mov rdi, [r8+TDT_OFFSET_IDENTIFICACION]
    call free

    ; Free the table
    mov rdi, [r15]
    call free
    mov qword [r15], 0

    pop r13
    pop r14
    pop r15
    ret

