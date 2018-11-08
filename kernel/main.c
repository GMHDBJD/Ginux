#include "proc.h"
#include "protect.h"
#include "global.h"

void print(char *);
void print_int(int);
void *memCpy(void *, void *, int);
void restart();

void delay(int);

void TestA();
void TestB();
void clockHandler(int i);
void put_irq_handler(int,irq_handler);
void enable_irq(int);

int kernel_main()
{
    interupt_num = 0;
    print("kernel_main\n");
    TASK *p_task = task_table;
    PROCESS *p_proc = proc_table;
    char *p_task_stack = task_stack + STACK_SIZE_TOTAL;
    u16 selector_ldt = SELECTOR_LDT_FIRST;
    for (int i = 0; i < NR_TASKS; ++i)
    {
        p_proc->pid = i;
        p_proc->ldt_sel = selector_ldt;
        memCpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5;
        memCpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK << 5;
        p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;
        p_proc->regs.eip = (u32)p_task->initial_eip;
        print(p_task->name);
        print("\n");
        p_proc->regs.esp = (u32)p_task_stack;
        p_proc->regs.eflags = 0x1202;
        p_task_stack -= p_task->stacksize;
        ++p_proc;
        ++p_task;
        selector_ldt += 1 << 3;
    }
    p_proc_ready = proc_table;
    put_irq_handler(CLOCK_IRQ, clockHandler);
    enable_irq(CLOCK_IRQ);
    restart();
    while (1)
    {
    }
}

void TestA()
{
    int i = 0;
    while (1)
    {
        print("A");
        print(".");
        delay(1);
    }
}

void TestB()
{
    while (1)
    {
        print("B");
        print(".");
        delay(1);
    }
}

void clockHandler(int i)
{
    ++p_proc_ready;
    if (p_proc_ready >= proc_table + NR_TASKS)
        p_proc_ready = proc_table;
}