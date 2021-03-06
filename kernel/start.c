#include "type.h"
#include "protect.h"
#include "proc.h"
#include "global.h"

void *memCpy(void *dst, void *src, int size);
void print(char *str);

void cstart()
{
    disp_pos = 0;
    print("\n\n\n\nKernel\n");
    print("hello world\n");
    memCpy(&gdt, (void *)(*((u32 *)(&gdt_ptr[2]))), *((u16 *)(&gdt_ptr[0])) + 1);
    u16 *p_gdt_limit = (u16 *)(&gdt_ptr[0]);
    *p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
    u32 *p_gdt_base = (u32 *)(&gdt_ptr[2]);
    *p_gdt_base = (u32)&gdt;
    u16 *p_idt_limit = (u16 *)(&idt_ptr[0]);
    u32 *p_idt_base = (u32 *)(&idt_ptr[2]);
    *p_idt_limit = IDT_SIZE * sizeof(GATE) - 1;
    *p_idt_base = (u32)&idt;
    init_prot();
}
