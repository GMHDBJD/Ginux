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

EXTERN TSS tss;

EXTERN PROCESS *p_proc_ready;

extern PROCESS proc_table[];
extern char task_stack[];

#endif