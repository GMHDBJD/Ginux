#define GLOBAL

#include "type.h"
#include "protect.h"
#include "proc.h"
#include "global.h"

void TestA();
void TestB();

TASK task_table[NR_TASKS] = {
    {TestA, STACK_SIZE_TESTA, "TestA"},
    {TestB, STACK_SIZE_TESTB, "TestB"}};

irq_handler irq_table[NR_IRQ];