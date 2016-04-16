global cropflip_asm


section .text
;void cropflip_asm		(
	;        rdi    | unsigned char *src,
	;        rsi    | unsigned char *dst,
	;        edx    | int cols,
	;        ecx    | int filas,
	;        r8d    | int src_row_size,
	;        r9d    | int dst_row_size,
	;        rbp+16 | int tamx,
	;        rbp+24 | int tamy,
	;        rbp+32 | int offsetx,
	;        rbp+40 | int offsety
;)


;			PSEUDO-ALTERNATIVA  FALOPA
;	src1 = src + offsetx*4 +src_row_size*(filas-1)
;	for(i = tamy ; i > 0 ; i--)
;		for (j = tamx/4 ; j > 0 ; j--)
;			xmm0 = [src1]
;			[dst] = xmm0
;			dst = dst + 16
;			src1 =  src1 + 16
;		src1 = src1 - (dst_row_size + src_row_size);


cropflip_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	
	
	movsx r12, dword [rbp+24]
	mov rdx, r12

	movsx r13, dword [rbp+16]
	sar r13, 2					; r13 <- tamx/4

	movsx r10, dword [rbp+32]
	movsx r11, dword [rbp+40]
	
	movsxd r8, r8d 					
	movsxd r9, r9d		

	mov rax, r8					; rax = src_row_size
	add rax, r9					; rax = src_row_size + dst_row_size	
			
	movsxd r14, ecx					; src1 = filas
	dec r14						; srci = filas-1
	imul r14, r8					; src1 = (filas-1)*src_row_size
	lea r14, [r14+ 4*r10]   			; src1 = 4*offsetx + (filas-1)*src_row_size
	add r14, rdi					; src1 = src + 4*offsetx + (filas-1)*src_row_size 

	


	;		rdi	 | src
	;		rsi	 | dst
	;		rdx	 | iterador filas / "i" 	
	;		rcx	 | iterador columnas / "j" 	
	;		r8   	 | src_row_size,
	;		r9   	 | dst_row_size,
	;		r10  	 | offsetx
	;		r11  	 | offsety
	;		r12  	 | tamy
	;		r13  	 | tamx/4
	;		r14  	 | src1
	;		rax	 | -(dst_row_size + src_row_size)
	;		Loop in y: tamy times
	; 		Loop in x: (32b * tamx / 128b) = tamx/4 times
	

.loopSkywalkerY:
	cmp rdx, 0
	je .fin
	mov rcx, r13
		
		.loopSkywalkerX:
			movdqu xmm0, [r14] 
			movdqu [rsi], xmm0 
			add r14, 16
			add rsi, 16
			loop .loopSkywalkerX

		.finLoopX:
			dec rdx
			sub r14, rax
			jmp .loopSkywalkerY
			
.fin:	
	pop r14
	pop r13
	pop r12
	pop rbp
	ret
