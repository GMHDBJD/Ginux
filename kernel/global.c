#define GLOBAL

#include "type.h"
#include "protect.h"
#include "proc.h"
#include "global.h"

PROCESS proc_table[NR_TASKS];

char task_stack[STACK_SIZE_TOTAL];