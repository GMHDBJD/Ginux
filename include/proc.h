#ifndef PROC_H_
#define PROC_H_
#include "type.h"
#include "protect.h"

#define NR_TASKS 1
#define LDT_SIZE 2
#define STACK_SIZE_TESTA 0x8000
#define STACK_SIZE_TOTAL STACK_SIZE_TESTA

typedef struct
{
    u32 gs;
    u32 fs;
    u32 es;
    u32 ds;
    u32 edi;
    u32 esi;
    u32 ebp;
    u32 kernel_esp;
    u32 ebx;
    u32 edx;
    u32 ecx;
    u32 eax;
    u32 retaddr;
    u32 eip;
    u32 cs;
    u32 eflags;
    u32 esp;
    u32 ss;
} Reg;

typedef struct
{
    Reg regs;
    u16 ldt_sel;
    DESCRIPTOR ldts[LDT_SIZE];
    u32 pid;
    char p_name[16];
} PROCESS;

#endif