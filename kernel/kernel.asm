P_STACKBASE	equ	0
GSREG		equ	P_STACKBASE
FSREG		equ	GSREG		+ 4
ESREG		equ	FSREG		+ 4
DSREG		equ	ESREG		+ 4
EDIREG		equ	DSREG		+ 4
ESIREG		equ	EDIREG		+ 4
EBPREG		equ	ESIREG		+ 4
KERNELESPREG	equ	EBPREG		+ 4
EBXREG		equ	KERNELESPREG	+ 4
EDXREG		equ	EBXREG		+ 4
ECXREG		equ	EDXREG		+ 4
EAXREG		equ	ECXREG		+ 4
RETADR		equ	EAXREG		+ 4
EIPREG		equ	RETADR		+ 4
CSREG		equ	EIPREG		+ 4
EFLAGSREG	equ	CSREG		+ 4
ESPREG		equ	EFLAGSREG	+ 4
SSREG		equ	ESPREG		+ 4
P_STACKTOP	equ	SSREG		+ 4
P_LDT_SEL	equ	P_STACKTOP
P_LDT		equ	P_LDT_SEL	+ 4

TSS3_S_SP0	equ	4

INT_M_CTL equ 0x20
INT_M_CTLMASK equ 0x21
EOI equ 0x20

SELECTOR_FLAT_C		equ		0x08
SELECTOR_TSS		equ		0x20
SELECTOR_KERNEL_CS	equ		SELECTOR_FLAT_C

extern cstart
extern gdt_ptr
extern idt_ptr
extern print
extern print_int
extern exception_handler
extern	spurious_irq
extern kernel_main
extern	p_proc_ready
extern	tss
extern delay
extern interupt_num
extern clockHandler
extern irq_table


bits 32

[SECTION .bss]
StackSapce  resb 2*1024
StackTop:

[SECTION .data]
DebugMessage db "Debug", 0xA,0

[SECTION .text]
global _start

global divide_error
global single_step_exception
global nmi
global breakpoint_exception
global overflow
global bounds_check
global inval_opcode
global copr_not_available
global double_fault
global copr_seg_overrun
global inval_tss
global segment_not_present
global stack_exception
global general_protection
global page_fault
global copr_error
global  hwint00
global  hwint01
global  hwint02
global  hwint03
global  hwint04
global  hwint05
global  hwint06
global  hwint07
global  hwint08
global  hwint09
global  hwint10
global  hwint11
global  hwint12
global  hwint13
global  hwint14
global  hwint15
global restart

_start:
    mov	esp, StackTop
    sgdt    [gdt_ptr]
    call    cstart
    lgdt    [gdt_ptr]
    lidt    [idt_ptr]
    jmp     SELECTOR_KERNEL_CS:csinit

csinit:
    xor	eax, eax
	mov	ax, SELECTOR_TSS
	ltr	ax
    jmp kernel_main

divide_error:
    push 0xFFFFFFFF
    push 0
    jmp exception

single_step_exception:
    push 0xFFFFFFFF
    push 1
    jmp exception

nmi:
    push 0xFFFFFFFF
    push 2
    jmp exception

breakpoint_exception:
    push 0xFFFFFFFF
    push 3
    jmp exception

overflow:
    push 0xFFFFFFFF
    push 4
    jmp exception

bounds_check:
    push 0xFFFFFFFF
    push 5
    jmp exception

inval_opcode:
    push 0xFFFFFFFF
    push 6
    jmp exception

copr_not_available:
    push 0xFFFFFFFF
    push 7
    jmp exception

double_fault:
    push 0xFFFFFFFF
    push 8
    jmp exception

copr_seg_overrun:
    push 0xFFFFFFFF
    push 9
    jmp exception

inval_tss:
    push 10
    jmp exception

segment_not_present:
    push 11
    jmp exception

stack_exception:
    push 12
    jmp exception

general_protection:
    push 13
    jmp exception

page_fault:
    push 14
    jmp exception

copr_error:
    push 0xFFFFFFFF
    push 16
    jmp exception

exception:
    call exception_handler
    add  esp, 4*2
    hlt

%macro  hwint_master    1
    call save
    in al, INT_M_CTLMASK
    or al, (1<<%1)
    mov al, EOI
    out INT_M_CTL, al
    sti
    push %1
    call [irq_table + 4*%1]
    pop ecx
    cli
    in al, INT_M_CTLMASK
    and al, ~(1 << %1)
    out INT_M_CTLMASK, al
    ret
%endmacro

ALIGN   16
hwint00:
    hwint_master    0

save:
    pushad
    push    ds
    push    es
    push    fs
    push    gs
    mov     dx, ss
    mov     ds, dx
    mov     es, dx
    mov     eax, esp
    inc     dword [interupt_num]
    cmp     dword [interupt_num], 0
    jne     .1
    mov     esp, StackTop
    push    restart
    jmp     [eax + RETADR - P_STACKBASE]
.1:
    push    re_enter
    jmp     [eax + RETADR - P_STACKBASE]



ALIGN   16
hwint01:
        hwint_master    1

ALIGN   16
hwint02:
        hwint_master    2

ALIGN   16
hwint03:
        hwint_master    3

ALIGN   16
hwint04:
        hwint_master    4

ALIGN   16
hwint05:
        hwint_master    5

ALIGN   16
hwint06:
        hwint_master    6

ALIGN   16
hwint07:
        hwint_master    7

%macro  hwint_slave     1
        push    %1
        call    spurious_irq
        add     esp, 4
        hlt
%endmacro

ALIGN   16
hwint08:
        hwint_slave     8

ALIGN   16
hwint09:
        hwint_slave     9

ALIGN   16
hwint10:
        hwint_slave     10

ALIGN   16
hwint11:
        hwint_slave     11

ALIGN   16
hwint12:
        hwint_slave     12

ALIGN   16
hwint13:
        hwint_slave     13

ALIGN   16
hwint14:
        hwint_slave     14

ALIGN   16
hwint15:
        hwint_slave     15


restart:
    mov esp, [p_proc_ready]
    lldt [esp+ P_LDT_SEL]
    lea  eax, [esp+P_STACKTOP]
    mov dword [tss+TSS3_S_SP0], eax
re_enter:
    dec dword [interupt_num]
    pop gs
    pop fs
    pop es
    pop ds
    popad
    add esp, 4
    iretd