#ifndef PROTECT_H_
#define PROTECT_H_

#include "type.h"


#define vir2phys(seg_base, vir) (u32)(((u32)seg_base) + (u32)(vir))

typedef struct
{
	u16 limit_low;
	u16 base_low;
	u8 base_mid;
	u8 attr1;
	u8 limit_high_attr2;
	u8 base_high;
} DESCRIPTOR;

typedef struct
{
	u16 offset_low;
	u16 selector;
	u8 dcount;
	u8 attr;
	u16 offset_high;
} GATE;

typedef struct
{
	u32 backlink;
	u32 esp0;
	u32 ss0;
	u32 esp1;
	u32 ss1;
	u32 esp2;
	u32 ss2;
	u32 cr3;
	u32 eip;
	u32 flags;
	u32 eax;
	u32 ecx;
	u32 edx;
	u32 ebx;
	u32 esp;
	u32 ebp;
	u32 esi;
	u32 edi;
	u32 es;
	u32 cs;
	u32 ss;
	u32 ds;
	u32 fs;
	u32 gs;
	u32 ldt;
	u16 trap;
	u16 iobase;
} TSS;

#define INDEX_TSS 4
#define INDEX_LDT_FIRST 5

#define SELECTOR_FLAT_C 0x08
#define	SELECTOR_FLAT_RW	0x10
#define SELECTOR_KERNEL_CS SELECTOR_FLAT_C
#define SELECTOR_KERNEL_DS SELECTOR_FLAT_RW
#define SELECTOR_KERNEL_GS SELECTOR_VIDEO
#define SELECTOR_TSS 0x20
#define	SELECTOR_VIDEO		(0x18+3)
#define SELECTOR_LDT_FIRST 0x28

#define SA_RPL_MASK 0xFFFC
#define SA_TI_MASK 0xFFFB
#define SA_TIL 4
#define SA_RPL_MASK 0xFFFC
#define SA_RPL0 0
#define SA_RPL1 1
#define SA_RPL2 2
#define SA_RPL3 3

#define RPL_KRNL SA_RPL0
#define RPL_TASK SA_RPL1
#define RPL_USER SA_RPL3

#define DA_386IGate 0x8E
#define DA_386TSS 0x89

#define INT_VECTOR_DIVIDE 0x0
#define INT_VECTOR_DEBUG 0x1
#define INT_VECTOR_NMI 0x2
#define INT_VECTOR_BREAKPOINT 0x3
#define INT_VECTOR_OVERFLOW 0x4
#define INT_VECTOR_BOUNDS 0x5
#define INT_VECTOR_INVAL_OP 0x6
#define INT_VECTOR_COPROC_NOT 0x7
#define INT_VECTOR_DOUBLE_FAULT 0x8
#define INT_VECTOR_COPROC_SEG 0x9
#define INT_VECTOR_INVAL_TSS 0xA
#define INT_VECTOR_SEG_NOT 0xB
#define INT_VECTOR_STACK_FAULT 0xC
#define INT_VECTOR_PROTECTION 0xD
#define INT_VECTOR_PAGE_FAULT 0xE
#define INT_VECTOR_COPROC_ERR 0x10
#define INT_VECTOR_IRQ0 0x20
#define INT_VECTOR_IRQ8 0x28

#define GDT_SIZE 128
#define IDT_SIZE 256

#define PRIVILEGE_KRNL 0
#define PRIVILEGE_TASK 1
#define PRIVILEGE_USER 3

#define DA_C 0x98
#define DA_DRW 0x92
#define DA_LDT 0x82


void init_8259A();

void exception_handler(int vec_no, int err_code, int eip, int cs, int eflags);
static void init_idt_desc(u8 vector, u8 desc_type, void (*handler)(), u8 privilege);
void init_prot();

#endif