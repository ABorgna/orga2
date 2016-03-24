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

; =====================================
; void tdt_agregarBloque(tdt* tabla, bloque* b)
tdt_agregarBloque:
    lea RSI, [RDI+3]
    jmp tdt_agregar

; =====================================
; void tdt_agregarBloques(tdt* tabla, bloque** b)
tdt_agregarBloques:
        
; =====================================
; void tdt_borrarBloque(tdt* tabla, bloque* b)
tdt_borrarBloque:
    jmp tdt_borrar
        
; =====================================
; void tdt_borrarBloques(tdt* tabla, bloque** b)
tdt_borrarBloques:
        
; =====================================
; void tdt_traducir(tdt* tabla, uint8_t* clave, uint8_t* valor)
tdt_traducir:
        
; =====================================
; void tdt_traducirBloque(tdt* tabla, bloque* b)
tdt_traducirBloque:

; =====================================
; void tdt_traducirBloques(tdt* tabla, bloque** b)
tdt_traducirBloques:
        
; =====================================
; void tdt_destruir(tdt** tabla)
tdt_destruir:


