#include "type.h"
#include "global.h"
#include "protect.h"

void print(char *);
void *memSet(void *ptr, int value, int num);
void print_int(int);

void divide_error();
void single_step_exception();
void nmi();
void breakpoint_exception();
void overflow();
void bounds_check();
void inval_opcode();
void copr_not_available();
void double_fault();
void copr_seg_overrun();
void inval_tss();
void segment_not_present();
void stack_exception();
void general_protection();
void page_fault();
void copr_error();
void hwint00();
void hwint01();
void hwint02();
void hwint03();
void hwint04();
void hwint05();
void hwint06();
void hwint07();
void hwint08();
void hwint09();
void hwint10();
void hwint11();
void hwint12();
void hwint13();
void hwint14();
void hwint15();
void exception_handler(int vec_no, int err_code, int eip, int cs, int eflags)
{
    char *err_msg[16] = {
        "divide 0",
        "debug",
        "nmi",
        "breakpoint",
        "overflow",
        "bounds_check",
        "inval_opcode",
        "copr_not_available",
        "double_fault",
        "copr_seg_overrun",
        "inval_tss",
        "segment_no_present",
        "stack_exception",
        "general_protection",
        "page_fault",
        "copr_error"};
    disp_pos = 8 * 80 * 2;
    print("Exception\n");
    print(err_msg[vec_no]);
    print("\n");
}

void init_idt_desc(u8 vector, u8 desc_type, int_handler handler, u8 privilege)
{
    idt[vector].offset_low = (u32)handler & 0xFFFF;
    idt[vector].selector = SELECTOR_KERNEL_CS;
    idt[vector].dcount = 0;
    idt[vector].attr = desc_type | (privilege << 5);
    idt[vector].offset_high = ((u32)handler >> 16) & 0xFFFF;
}

static void init_descriptor(DESCRIPTOR *p_desc, u32 base, u32 limit, u16 attribute)
{
    p_desc->limit_low = limit & 0x0FFFF;
    p_desc->base_low = base & 0x0FFFF;
    p_desc->base_mid = (base >> 16) & 0x0FF;
    p_desc->attr1 = attribute & 0x0FF;
    p_desc->limit_high_attr2 = ((limit >> 16) & 0x0F) | (attribute >> 8) & 0xF0;
    p_desc->base_high = (base >> 24) & 0x0FF;
}

u32 seg2phys(u16 seg)
{
    DESCRIPTOR *p_dest = &gdt[seg >> 3];
    return (p_dest->base_high << 24 | p_dest->base_mid << 16 | p_dest->base_low);
}

void init_prot()
{
    init_8259A();
    init_idt_desc(INT_VECTOR_DIVIDE, DA_386IGate, divide_error, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_DEBUG, DA_386IGate, single_step_exception, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_NMI, DA_386IGate, nmi, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_BREAKPOINT, DA_386IGate, breakpoint_exception, PRIVILEGE_USER);
    init_idt_desc(INT_VECTOR_OVERFLOW, DA_386IGate, overflow, PRIVILEGE_USER);
    init_idt_desc(INT_VECTOR_BOUNDS, DA_386IGate, bounds_check, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_INVAL_OP, DA_386IGate, inval_opcode, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_COPROC_NOT, DA_386IGate, copr_not_available, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_DOUBLE_FAULT, DA_386IGate, double_fault, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_COPROC_SEG, DA_386IGate, copr_seg_overrun, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_INVAL_TSS, DA_386IGate, inval_tss, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_SEG_NOT, DA_386IGate, segment_not_present, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_STACK_FAULT, DA_386IGate, stack_exception, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_PROTECTION, DA_386IGate, general_protection, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_PAGE_FAULT, DA_386IGate, page_fault, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_COPROC_ERR, DA_386IGate, copr_error, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ0 + 0, DA_386IGate, hwint00, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ0 + 1, DA_386IGate, hwint01, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ0 + 2, DA_386IGate, hwint02, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ0 + 3, DA_386IGate, hwint03, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ0 + 4, DA_386IGate, hwint04, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ0 + 5, DA_386IGate, hwint05, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ0 + 6, DA_386IGate, hwint06, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ0 + 7, DA_386IGate, hwint07, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ8 + 0, DA_386IGate, hwint08, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ8 + 1, DA_386IGate, hwint09, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ8 + 2, DA_386IGate, hwint10, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ8 + 3, DA_386IGate, hwint11, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ8 + 4, DA_386IGate, hwint12, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ8 + 5, DA_386IGate, hwint13, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ8 + 6, DA_386IGate, hwint14, PRIVILEGE_KRNL);
    init_idt_desc(INT_VECTOR_IRQ8 + 7, DA_386IGate, hwint15, PRIVILEGE_KRNL);
    memSet(&tss, 0, sizeof(tss));
    tss.ss0 = SELECTOR_KERNEL_DS;
    init_descriptor(&gdt[INDEX_TSS], vir2phys(seg2phys(SELECTOR_KERNEL_DS), &tss), sizeof(tss) - 1, DA_386TSS);
    tss.iobase = sizeof(tss);
    PROCESS *p_proc = proc_table;
    u16 selector_ldt = INDEX_LDT_FIRST << 3;
    for (int i = 0; i < NR_TASKS; ++i)
    {
        init_descriptor(&gdt[selector_ldt >> 3], vir2phys(seg2phys(SELECTOR_KERNEL_DS), proc_table[i].ldts), LDT_SIZE * sizeof(DESCRIPTOR) - 1, DA_LDT);
        ++p_proc;
        selector_ldt += 1 << 3;
    }
}