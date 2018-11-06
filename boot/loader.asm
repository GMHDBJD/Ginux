org	0x100
jmp LABEL_START

%include "fat12.inc"
%include "macro.inc"

LoadMessage: db "Loading..."
wSectorNo dw 0
KenelFileName db "KERNEL  BIN", 0
wRootDirSizeForLoop dw RootDirSectors
NotFound: db "Not Found"

BaseOfLoader equ 0x9000
OffsetOfLoader equ 0x100
BaseOfLoaderPhyAddr equ BaseOfLoader*0x10
BaseOfStack equ 0x100
BaseOfKernel equ 0x8000
OffsetOfKernel equ 0
PageDirBase	equ	0x200000
PageTblBase	equ	0x201000

LABEL_GDT: Descriptor 0,0,0
LABEL_DESC_FLAT_C: Descriptor 0,0xfffff,DA_CR|DA_32|DA_LIMIT_4K
LABEL_DESC_FLAT_RW: Descriptor 0,0xfffff,DA_DRW|DA_32|DA_LIMIT_4K
LABEL_DESC_VIDEO: Descriptor 0xB8000,0xffff,DA_DRW | DA_DPL3



GdtLen equ $-LABEL_GDT
GdtPtr dw GdtLen-1
       dd BaseOfLoaderPhyAddr + LABEL_GDT

SelectorFlatC  equ LABEL_DESC_FLAT_C - LABEL_GDT
SelectorFlatRW equ LABEL_DESC_FLAT_RW - LABEL_GDT
SelectorVideo equ LABEL_DESC_VIDEO - LABEL_GDT + SA_RPL3

LABEL_START:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack
	mov	ax,	LoadMessage
    mov cx, 10
    mov dh, 1
	call PRINT
    mov word [wSectorNo], SectorNoOfRootDirectory
    mov ebx, 0
    mov di, _MemChkBuf
MemChkLoop:
    mov eax, 0xE820
    mov ecx, 20
    mov edx, 0x534D4150
    int 0x15
    jc  MemChkFail
    add di, 20
    inc dword [_dwMCRNumber]
    cmp ebx, 0
    jne MemChkLoop
    jmp MemChkOK
MemChkFail:
    mov dword [_dwMCRNumber], 0
MemChkOK:
    xor ah, ah
    xor dl, dl
    int 0x13
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
    cmp word [wRootDirSizeForLoop], 0
    jz  LABEL_NO_KERNELBIN
    dec word [wRootDirSizeForLoop]
    mov ax, BaseOfKernel
    mov es, ax
    mov bx, OffsetOfKernel
    mov ax, [wSectorNo]
    mov cl, 1
    call ReadSector
    mov  si, KenelFileName
    mov  di, OffsetOfKernel
    cld
    mov  dx, 0x10
LABEL_SEARCH_FOR_KERNELBIN:
    cmp  dx, 0
    jz   LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
    dec  dx
    mov  cx, 11
LABEL_CMP_FILENAME:
    cmp cx, 0
    jz  LABEL_FILENAME_FOUND
    dec cx
    lodsb
    cmp al, byte [es:di]
    jz  LABEL_GO_ON
    jmp LABEL_DIFFERENT
LABEL_GO_ON:
    inc di
    jmp LABEL_CMP_FILENAME
LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
    add word [wSectorNo], 1
    jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN
LABEL_DIFFERENT:
    and di, 0xFFE0
    add di, 0x20
    mov si, KenelFileName
    jmp LABEL_SEARCH_FOR_KERNELBIN
LABEL_FILENAME_FOUND:
    mov  ax, RootDirSectors
    and  di, 0xFFE0
    add  di, 0x1A
    mov  cx, word [es:di]
    push cx
    add  cx, ax
    add  cx, DeltaSectorNo
    mov  ax, BaseOfKernel
    mov  es, ax
    mov  bx, OffsetOfKernel
    mov  ax, cx
LABEL_GOON_LOADING_FILE:
    mov  cl, 1
    call ReadSector
    pop  ax
    call GetFATEntry
    cmp  ax, 0xFFF
    jz   LABEL_FILE_LOADED
    push ax
    mov  dx, RootDirSectors
    add  ax, dx
    add  ax, DeltaSectorNo
    add  bx, [BPB_BytsPerSec]
    jmp  LABEL_GOON_LOADING_FILE

LABEL_NO_KERNELBIN:
    mov ax, ds
    mov es, ax
	mov	ax,	NotFound
    mov dh, 2
	mov	cx, 9
	call PRINT
    jmp $
ReadSector:
    push bp
    mov  bp, sp
    sub  esp, 2
    mov  byte [bp-2], cl
    push bx
    mov  bl, [BPB_SecPerTrk]
    div  bl
    inc  ah
    mov  cl, ah
    mov  dh, al
    shr  al, 1
    mov  ch, al
    and  dh, 1
    pop  bx
    mov  dl, [BS_DrvNum]
GoOnReading:
    mov  ah, 2
    mov  al, byte [bp-2]
    int  0x13
    jc   GoOnReading
    add  esp, 2
    pop  bp
    ret

GetFATEntry:
    push es
    push bx
    push ax
    mov  ax, BaseOfKernel
    sub  ax, 0x100
    mov  es, ax
    pop  ax
    mov  byte [0], 0
    mov  bx, 3
    mul  bx
    mov  bx, 2
    div  bx
    cmp  dx, 0
    jz   LABEL_EVEN
    mov  byte [0], 1
LABEL_EVEN:
    xor  dx, dx
    mov  bx, [BPB_BytsPerSec]
    div  bx
    push dx
    mov  bx, 0
    add  ax, SectorNoOfFAT1
    mov  cl, 2
    call ReadSector
    pop  dx
    add  bx, dx
    mov  ax, [es:bx]
    cmp  byte [0], 1
    jnz  LABEL_EVEN_2
    shr  ax, 4
LABEL_EVEN_2:
    and  ax, 0xFFF
    pop  bx
    pop  es
    ret

PRINT:
	mov	bp, ax
	mov	ax, 0x1301
	mov	bx, 0x00c
	mov	dl, 0
	int	0x10
	ret
KillMotor:
	push dx
	mov  dx, 0x3F2
	mov  al, 0
	out  dx, al
	pop  dx
	ret

LABEL_FILE_LOADED:
	call KillMotor
    mov ax, ds
    mov es, ax
    lgdt [GdtPtr]
    cli
    in al, 0x92
    or al, 00000010b
    out 0x92, al
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp dword SelectorFlatC:(BaseOfLoaderPhyAddr+LABEL_PM_START)


[SECTION .s32]
ALIGN 32
[BITS 32]



LABEL_PM_START:
    mov ax, SelectorVideo
    mov gs, ax
    mov ax, SelectorFlatRW
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov esp, TopOfStack
    push Protect
    call DispStr
    add esp, 4
    call MemInfo
    call SetupPaging
    call InitKernel
    jmp  SelectorFlatC:KernelEntryPointPhyAddr

MemInfo:
    push esi
    push edi
    push ecx
    mov  esi, MemChkBuf
    mov  ecx, [dwMCRNumber]
.loop:
    mov edx, 5
    mov edi, ARDStruct
.1:
    mov eax, [esi]
	stosd
	add	esi, 4
	dec	edx
	cmp	edx, 0
	jnz	.1
	cmp	dword [dwType], 1
	jne	.2
	mov	eax, [dwBaseAddrLow]
	add	eax, [dwLengthLow]
	cmp	eax, [dwMemSize]
	jb	.2
	mov	[dwMemSize], eax
.2:
	loop	.loop
	pop	ecx
	pop	edi
	pop	esi
	ret

SetupPaging:
    push SetupPage
    call DispStr
    add esp, 4
    xor edx, edx
    mov eax, [dwMemSize]
    mov ebx, 0x4000000
    div ebx
    mov ecx, eax
    test edx, edx
    jz  no_remainder
    inc  ecx
no_remainder:
    push ecx
    mov  ax, SelectorFlatRW
    mov  es, ax
    mov  edi, PageDirBase
    xor  eax, eax
    mov  eax, PageTblBase | PG_P | PG_USU | PG_RWW
.1:
	stosd
	add	eax, 4096
	loop	.1
	pop	eax
	mov	ebx, 1024
	mul	ebx
	mov	ecx, eax
	mov	edi, PageTblBase
	xor	eax, eax
	mov	eax, PG_P  | PG_USU | PG_RWW
.2:
	stosd
	add	eax, 4096
	loop	.2
	mov	eax, PageDirBase
	mov	cr3, eax
	mov	eax, cr0
	or	eax, 0x80000000
	mov	cr0, eax
	jmp	short .3
.3:
	nop
	ret

InitKernel:
    xor esi, esi
    mov cx, word [BaseOfKernelFilePhyAddr + 0x2C]
    movzx ecx, cx
    mov esi, [BaseOfKernelFilePhyAddr + 0x1C]
    add esi, BaseOfKernelFilePhyAddr
.Begin:
    mov eax, [esi+0]
    cmp eax, 0
    jz  .NoAction
    push dword [esi+0x10]
    mov eax, [esi+ 0x4]
    add eax, BaseOfKernelFilePhyAddr
    push eax
    push dword [esi+0x8]
    call MemCpy
    add  esp, 12
.NoAction:
    add esi, 0x20
    dec ecx
    jnz .Begin
    ret


DispAL:
	push	ecx
	push	edx
	push	edi
	mov	edi, [dwDispPos]
	mov	ah, 0xF
	mov	dl, al
	shr	al, 4
	mov	ecx, 2
.begin:
	and	al, 01111b
	cmp	al, 9
	ja	.1
	add	al, '0'
	jmp	.2
.1:
	sub	al, 0xA
	add	al, 'A'
.2:
	mov	[gs:edi], ax
	add	edi, 2
	mov	al, dl
	loop	.begin
	mov	[dwDispPos], edi
	pop	edi
	pop	edx
	pop	ecx
	ret
DispInt:
	mov	eax, [esp + 4]
	shr	eax, 24
	call	DispAL
	mov	eax, [esp + 4]
	shr	eax, 16
	call	DispAL
	mov	eax, [esp + 4]
	shr	eax, 8
	call	DispAL
	mov	eax, [esp + 4]
	call	DispAL
	mov	ah, 0x7
	mov	al, 'h'
	push	edi
	mov	edi, [dwDispPos]
	mov	[gs:edi], ax
	add	edi, 4
	mov	[dwDispPos], edi
	pop	edi
	ret
DispStr:
	push	ebp
	mov	ebp, esp
	push	ebx
	push	esi
	push	edi
	mov	esi, [ebp + 8]
	mov	edi, [dwDispPos]
    mov ah, 0xf
.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0xA
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
	mov	[dwDispPos], edi
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
DispReturn:
	push	szReturn
	call	DispStr
	add	esp, 4
	ret


MemCpy:
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


[SECTION .data]
ALIGN 32
LABEL_DATA:
_MemChkBuf times 256 db 0
_dwMCRNumber: dd 0
_ARDStruct:
  _dwBaseAddrLow:		dd	0
  _dwBaseAddrHigh:		dd	0
  _dwLengthLow:			dd	0
  _dwLengthHigh:		dd	0
  _dwType:			dd	0
_szRAMSize:	db "RAM size:", 0
_dwMemSize:	dd 0
_szMemChkTitle:	db "BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0xA, 0
_DebugMessage: db "Debug", 0xA,0
_szReturn:	db 0xA, 0
_dwDispPos:	dd (80 * 2 + 0) * 2
_Protect: db "Protect...",0xA,0
_SetupPage: db "SetupPage...",0xA,0

Protect equ BaseOfLoaderPhyAddr + _Protect
SetupPage equ BaseOfLoaderPhyAddr + _SetupPage
DebugMessage        equ BaseOfLoaderPhyAddr + _DebugMessage
szMemChkTitle		equ	BaseOfLoaderPhyAddr + _szMemChkTitle
MemChkBuf equ BaseOfLoaderPhyAddr + _MemChkBuf
dwMCRNumber equ BaseOfLoaderPhyAddr + _dwMCRNumber
ARDStruct		equ	BaseOfLoaderPhyAddr + _ARDStruct
	dwBaseAddrLow	equ	BaseOfLoaderPhyAddr + _dwBaseAddrLow
	dwBaseAddrHigh	equ	BaseOfLoaderPhyAddr + _dwBaseAddrHigh
	dwLengthLow	equ	BaseOfLoaderPhyAddr + _dwLengthLow
	dwLengthHigh	equ	BaseOfLoaderPhyAddr + _dwLengthHigh
	dwType		equ	BaseOfLoaderPhyAddr + _dwType
szRAMSize		equ	BaseOfLoaderPhyAddr + _szRAMSize
dwMemSize		equ	BaseOfLoaderPhyAddr + _dwMemSize
szReturn		equ	BaseOfLoaderPhyAddr + _szReturn
dwDispPos		equ	BaseOfLoaderPhyAddr + _dwDispPos

BaseOfKernelFilePhyAddr	equ	BaseOfKernel * 0x10
KernelEntryPointPhyAddr	equ	0x30400


StackSpace times 1024 db 0
TopOfStack equ BaseOfLoaderPhyAddr + $