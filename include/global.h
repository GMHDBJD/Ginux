#ifndef GLOBAL_H_
#define GLOBAL_H_
#include "proc.h"

#define EXTERN extern

#ifdef GLOBAL
#undef EXTERN
#define EXTERN
#endif

EXTERN int disp_pos;
EXTERN u8 gdt_ptr[6];
EXTERN DESCRIPTOR gdt[GDT_SIZE];
EXTERN u8 idt_ptr[6];
EXTERN GATE idt[IDT_SIZE];
EXTERN int interupt_num;

EXTERN TSS tss;

EXTERN PROCESS *p_proc_ready;

EXTERN PROCESS proc_table[NR_TASKS];
EXTERN char task_stack[STACK_SIZE_TOTAL];
extern TASK task_table[NR_TASKS];
extern irq_handler irq_table[];

#endif