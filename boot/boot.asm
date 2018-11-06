org 0x7c00
BaseOfStack     equ     0x7c00

jmp LABEL_START
nop
%include "fat12.inc"

wSectorNo dw 0
wRootDirSizeForLoop dw RootDirSectors
BaseOfLoader equ 0x9000
OffsetOfLoader equ 0x100
LoaderFileName db "LOADER  BIN", 0
NotFound: db "Not Found"
BootMessage:	db "Booting..."
LABEL_START:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack
    xor ah, ah
    xor dl, dl
    int 0x13
    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0
    mov dx, 0x184f
    int 0x10
    mov dh, 0
	mov	ax,	BootMessage
    mov cx, 10
	call PRINT
    mov word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
    cmp word [wRootDirSizeForLoop], 0
    jz  LABEL_NO_LOADERBIN
    dec word [wRootDirSizeForLoop]
    mov ax, BaseOfLoader
    mov es, ax
    mov bx, OffsetOfLoader
    mov ax, [wSectorNo]
    mov cl, 1
    call ReadSector
    mov  si, LoaderFileName
    mov  di, OffsetOfLoader
    cld
    mov  dx, 0x10
LABEL_SEARCH_FOR_LOADERBIN:
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
    mov si, LoaderFileName
    jmp LABEL_SEARCH_FOR_LOADERBIN
LABEL_FILENAME_FOUND:
    mov  ax, RootDirSectors
    and  di, 0xFFE0
    add  di, 0x1A
    mov  cx, word [es:di]
    push cx
    add  cx, ax
    add  cx, DeltaSectorNo
    mov  ax, BaseOfLoader
    mov  es, ax
    mov  bx, OffsetOfLoader
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

LABEL_NO_LOADERBIN:
    mov ax, ds
    mov es, ax
	mov	ax,	NotFound
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
    mov  ax, BaseOfLoader
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

LABEL_FILE_LOADED:
    jmp BaseOfLoader:OffsetOfLoader

PRINT:
	mov	bp, ax
	mov	ax, 0x1301
	mov	bx, 0x00c
	mov	dl, 0
	int	0x10
	ret

times 	510-($-$$)	db	0
dw 	0xaa55