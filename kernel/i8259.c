#include "type.h"
#include "proc.h"
#include "global.h"

#define INT_M_CTL 0x20
#define INT_M_CTLMASK 0x21
#define INT_S_CTL 0xA0
#define INT_S_CTLMASK 0xA1
#define INT_VECTOR_IRQ0 0x20
#define INT_VECTOR_IRQ8 0x28

void out_byte(u16 port, u8 value);
u8 in_byte(u16 port);
void print(char *);
void print_int(int);
void spurious_irq(int);

void init_8259A()
{
    out_byte(INT_M_CTL, 0x11);
    out_byte(INT_S_CTL, 0x11);
    out_byte(INT_M_CTLMASK, INT_VECTOR_IRQ0);
    out_byte(INT_S_CTLMASK, INT_VECTOR_IRQ8);
    out_byte(INT_M_CTLMASK, 0x4);
    out_byte(INT_S_CTLMASK, 0x2);
    out_byte(INT_M_CTLMASK, 0x1);
    out_byte(INT_S_CTLMASK, 0x1);
    out_byte(INT_M_CTLMASK, 0xFF);
    out_byte(INT_S_CTLMASK, 0xFF);
    for (int i = 0; i < NR_IRQ; ++i)
    {
        irq_table[i] = spurious_irq;
    }
}

void spurious_irq(int irq)
{
    print("spurious_irq: ");
    print_int(irq);
    print("\n");
}

void put_irq_handler(int irq, irq_handler handler)
{
    disable_irq(irq);
    irq_table[irq] = handler;
}