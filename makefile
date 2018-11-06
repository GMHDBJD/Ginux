#########################
# Makefile for Orange'S #
#########################

# Entry point of Orange'S
# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc!
ENTRYPOINT	= 0x30400

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET	=   0x400

# Programs, flags, etc.
ASM		= nasm
DASM		= ndisasm
CC		= gcc
LD		= ld
ASMBFLAGS	= -I boot/include/
LOADFLAGS   = -I boot/include/ -f elf_i386
ASMKFLAGS	= -I include/ -f elf
CFLAGS		= -fno-stack-protector -I include/ -c -m32 -fno-builtin
LDFLAGS		= -s -m elf_i386 -Ttext   $(ENTRYPOINT)
DASMFLAGS	= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# This Program
ORANGESBOOT	= boot/boot.bin boot/loader.bin
ORANGESKERNEL	= kernel.bin
OBJS		= kernel/kernel.o kernel/start.o kernel/i8259.o kernel/protect.o kernel/main.o kernel/global.o lib/clib.o  lib/lib.o
DASMOUTPUT	= kernel.bin.asm

# All Phony Targets
.PHONY : everything final image clean realclean disasm all buildimg

# Default starting position
everything : $(ORANGESBOOT) $(ORANGESKERNEL)

all : realclean everything

final : all clean

image : final buildimg

clean :
	rm -f $(OBJS)

realclean :
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

disasm :
	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)

# We assume that "a.img" exists in current folder
buildimg :
	dd if=boot/boot.bin of=a.img bs=512 count=1 conv=notrunc
	sudo mount -o loop a.img /mnt/floppy/
	sudo cp -fv boot/loader.bin /mnt/floppy/
	sudo cp -fv kernel.bin /mnt/floppy
	sudo umount /mnt/floppy

boot/boot.bin : boot/boot.asm  boot/include/fat12.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm  \
			boot/include/fat12.inc boot/include/macro.inc
	$(ASM) $(ASMBFLAGS)  -o $@ $<

$(ORANGESKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $(ORANGESKERNEL) $(OBJS)

kernel/kernel.o : kernel/kernel.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/protect.o : kernel/protect.c include/type.h include/global.h include/protect.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/start.o : kernel/start.c include/type.h include/protect.h include/proc.h include/global.h
	$(CC) $(CFLAGS) -o $@ $<


kernel/i8259.o : kernel/i8259.c include/type.h
	$(CC) $(CFLAGS) -o $@ $<


kernel/main.o : kernel/main.c include/proc.h include/protect.h include/global.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/global.o : kernel/global.c include/type.h include/protect.h include/proc.h include/global.h
	$(CC) $(CFLAGS) -o $@ $<

lib/clib.o : lib/clib.c
	$(CC) $(CFLAGS) -o $@ $<


lib/lib.o : lib/lib.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<