extern	disp_pos

INT_M_CTLMASK	equ	0x21
INT_S_CTLMASK	equ	0xA1

[SECTION .text]

global print
global memCpy
global memSet
global out_byte
global disp_pos
global disable_irq
global enable_irq

print:
	push	ebp
	mov	ebp, esp
	mov	esi, [ebp + 8]
	mov	edi, [disp_pos]
    mov ah, 0xf
.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah
	jnz	.3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.1
.3:
	mov ah, 0xC
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1

.2:
	mov	[disp_pos], edi
	pop	ebp
	ret


memCpy:
	push	ebp
	mov	ebp, esp
	push	esi
	push	edi
	push	ecx
	mov	edi, [ebp + 8]
	mov	esi, [ebp + 12]
	mov	ecx, [ebp + 16]

.1:
	cmp	ecx, 0
	jz	.2
	mov	al, [ds:esi]
	inc	esi
	mov	byte [es:edi], al
	inc	edi
	dec	ecx
	jmp	.1
.2:
	mov	eax, [ebp + 8]
	pop	ecx
	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp
	ret

out_byte:
	mov	edx, [esp + 4]
	mov	al, [esp + 4 + 4]
	out	dx, al
	nop
	nop
	ret

in_byte:
	mov	edx, [esp + 4]
	xor	eax, eax
	in	al, dx
	nop
	nop
	ret

memSet:
	push	ebp
	mov	ebp, esp

	push	esi
	push	edi
	push	ecx

	mov	edi, [ebp + 8]
	mov	edx, [ebp + 12]
	mov	ecx, [ebp + 16]
.1:
	cmp	ecx, 0
	jz	.2

	mov	byte [edi], dl
	inc	edi

	dec	ecx
	jmp	.1
.2:

	pop	ecx
	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp

	ret

disable_irq:
        mov     ecx, [esp + 4]
        pushf
        cli
        mov     ah, 1
        rol     ah, cl
        cmp     cl, 8
        jae     disable_8
disable_0:
        in      al, INT_M_CTLMASK
        test    al, ah
        jnz     dis_already
        or      al, ah
        out     INT_M_CTLMASK, al
        popf
        mov     eax, 1
        ret
disable_8:
        in      al, INT_S_CTLMASK
        test    al, ah
        jnz     dis_already
        or      al, ah
        out     INT_S_CTLMASK, al
        popf
        mov     eax, 1
        ret
dis_already:
        popf
        xor     eax, eax
        ret

enable_irq:
        mov     ecx, [esp + 4]
        pushf
        cli
        mov     ah, ~1
        rol     ah, cl
        cmp     cl, 8
        jae     enable_8
enable_0:
        in      al, INT_M_CTLMASK
        and     al, ah
        out     INT_M_CTLMASK, al
        popf
        ret
enable_8:
        in      al, INT_S_CTLMASK
        and     al, ah
        out     INT_S_CTLMASK, al
        popf
        ret