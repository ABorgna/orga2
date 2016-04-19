global copyN
global copyN_sse
global copyN_avx2

copyN:
copyN_sse:
    ; Copy rbx pixels from [rsi] to [rdi]
    ; Modifies rsi, rdi, rcx, r11, and xmm0-15
    mov rcx, rbx
    shr rcx, 6
    jnz .copy64
    jmp .copy64End
    .copy64:
        ; 64 pixels (256B) per loop
        movdqu xmm0, [rsi]
        movdqu xmm1, [rsi+16]
        movdqu xmm2, [rsi+32]
        movdqu xmm3, [rsi+48]
        movdqu xmm4, [rsi+64]
        movdqu xmm5, [rsi+80]
        movdqu xmm6, [rsi+96]
        movdqu xmm7, [rsi+112]
        movdqu xmm8, [rsi+128]
        movdqu xmm9, [rsi+144]
        movdqu xmm10, [rsi+160]
        movdqu xmm11, [rsi+176]
        movdqu xmm12, [rsi+192]
        movdqu xmm13, [rsi+208]
        movdqu xmm14, [rsi+224]
        movdqu xmm15, [rsi+240]

        movdqu [rdi], xmm0
        movdqu [rdi+16], xmm1
        movdqu [rdi+32], xmm2
        movdqu [rdi+48], xmm3
        movdqu [rdi+64], xmm4
        movdqu [rdi+80], xmm5
        movdqu [rdi+96], xmm6
        movdqu [rdi+112], xmm7
        movdqu [rdi+128], xmm8
        movdqu [rdi+144], xmm9
        movdqu [rdi+160], xmm10
        movdqu [rdi+176], xmm11
        movdqu [rdi+192], xmm12
        movdqu [rdi+208], xmm13
        movdqu [rdi+224], xmm14
        movdqu [rdi+240], xmm15

        add rdi, 256
        add rsi, 256

        dec rcx
        jz .copy64End
        jmp .copy64
    .copy64End:
    mov rcx, rbx
    shr rcx, 2
    and rcx, 0xf
    jrcxz .copy4End
    .copy4:
        ; 4 pixels (16B) per loop
        movq xmm0, [rsi]
        movq [rdi], xmm0

        add rdi, 16
        add rsi, 16
    loop .copy4
    .copy4End:
    mov rcx, rbx
    and rcx, 0x3
    jrcxz .copy1End
    .copy1:
        ; 1 pixel (4B) per loop
        mov r11d, [rsi]
        mov [rdi], r11d

        add rdi, 4
        add rsi, 4
    loop .copy1
    .copy1End:

    ret

copyN_avx2:
    ; Copy rbx pixels from [rsi] to [rdi]
    ; Modifies rsi, rdi, rcx, r11, and ymm0-15
    mov rcx, rbx
    shr rcx, 7
    jnz .copy128
    jmp .copy128End
    .copy128:
        ; 128 pixels (512B) per loop
        vmovdqu ymm0, [rsi]
        vmovdqu ymm1, [rsi+32]
        vmovdqu ymm2, [rsi+64]
        vmovdqu ymm3, [rsi+96]
        vmovdqu ymm4, [rsi+128]
        vmovdqu ymm5, [rsi+160]
        vmovdqu ymm6, [rsi+192]
        vmovdqu ymm7, [rsi+224]
        vmovdqu ymm8, [rsi+256]
        vmovdqu ymm9, [rsi+288]
        vmovdqu ymm10, [rsi+320]
        vmovdqu ymm11, [rsi+352]
        vmovdqu ymm12, [rsi+384]
        vmovdqu ymm13, [rsi+416]
        vmovdqu ymm14, [rsi+448]
        vmovdqu ymm15, [rsi+480]

        vmovdqu [rdi], ymm0
        vmovdqu [rdi+32], ymm1
        vmovdqu [rdi+64], ymm2
        vmovdqu [rdi+96], ymm3
        vmovdqu [rdi+128], ymm4
        vmovdqu [rdi+160], ymm5
        vmovdqu [rdi+192], ymm6
        vmovdqu [rdi+224], ymm7
        vmovdqu [rdi+256], ymm8
        vmovdqu [rdi+288], ymm9
        vmovdqu [rdi+320], ymm10
        vmovdqu [rdi+352], ymm11
        vmovdqu [rdi+384], ymm12
        vmovdqu [rdi+416], ymm13
        vmovdqu [rdi+448], ymm14
        vmovdqu [rdi+480], ymm15

        add rdi, 512
        add rsi, 512

        dec rcx
        jz .copy128End
        jmp .copy128
    .copy128End:
    mov rcx, rbx
    shr rcx, 8
    and rcx, 0xf
    jrcxz .copy8End
    .copy8:
        ; 8 pixels (32B) per loop
        vmovdqu ymm0, [rsi]
        vmovdqu [rdi], ymm0

        add rdi, 32
        add rsi, 32
    loop .copy8
    .copy8End:
    mov rcx, rbx
    and rcx, 0x7
    jrcxz .copy1End
    .copy1:
        ; 1 pixel (4B) per loop
        mov r11d, [rsi]
        mov [rdi], r11d

        add rdi, 4
        add rsi, 4
    loop .copy1
    .copy1End:

    ret


