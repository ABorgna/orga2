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


; 			alternativa falopa:
; 	temp = src + src_row_size*(filas-1) + offsetx*4
;	for(i = tamy ; i > 0 ; i--)
;		for (j = tamx/4 ; j > 0 ; j = j - 16)
;			xmm0 = [temp]
;			[dst] = xmm0
;			dst = dst + 16
;           temp = temp + 16
;		temp = temp - src_row_size - tamx*4


;			PSEUDO-POSTA (TAMBIEN FALOPA):
;	src1 = src + offsetx*4 +src_row_size*offsety
;	dst1 = dst + (tamy-1)*dst_row_size
;	for(i = tamy ; i > 0 ; i--)
;		for (j = tamx/4 ; j > 0 ; j--)
;			xmm0 = [src1]
;			[dst1] = xmm0
;			dst1 = dst1 + 16
;			src1 =  src1 + 16
;		src1 = src1 + offsetx;
;		
cropflip_asm:
	push rbp
	mov rbp, rsp
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	
	
	movsx r12, dword [rbp+24]
	mov rdx, r12
	movsx r13, dword [rbp+16]
	sar r13, 2			; r13 <- tamx/4
	movsx r10, dword [rbp+32]
	movsx r11, dword [rbp+40]
	
	movsxd r8, r8d 				
	movsxd r9, r9d		
			
	mov r14, r11			; src1 = offsety
	imul r14, r8			; src1 = offsety*src_row_size
	lea r14, [r14+ 4*r11]   	; src1 = 4*offstx + offsety*src_row_size
	lea r14, [r14 + rdi]		; src1 = src + 4*offstx + offsety*src_row_size
	
	mov r15, r12			; dst1 = tamy
	dec r15				; dst1 = tamy -1
	imul r15, r9			; dst1 = (tamy-1)*dst_row_size
	lea r15, [r15 + rsi]		; dst1 = dst + (tamy-1)*dst_row_size
	



	;		rdi	 | src
	;		rsi	 | dst
	;		rdx	 | iterador filas / "i" 	
	;		rcx	 | iterador columnas / "j" 	
			r8   	 | src_row_size,
			r9   	 | dst_row_size,
	;		r10  	 | offsetx
	;		r11  	 | offsety
	;		r12  	 | tamy
	;		r13  	 | tamx/4
	;		r14  	 | src1 
	;		r15	 | dst1
	;		Loop in y: tamy times
	; 		Loop in x: (32b * tamx / 128b) = tamx/4 times
	

.loopSkywalkerY:
	cmp rdx, 0
	je .fin
		mov rcx, r13
		
		.loopSkywalkerX:
			movdqu xmm0, [r14] 
			movdqu [r15], xmm0 
			add r14, 16
			add r15, 16
			loop .loopSkywalkerX

		.finLoopX:
			dec rdx
			lea r14, [r14 + r10]
			jmp .loopSkywalkerY
			
.fin:	
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop rbp
	ret
