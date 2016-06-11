# ** por compatibilidad se omiten tildes **
# ==============================================================================
# TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
# ==============================================================================

MCOPY=mcopy

KERNEL_SRC=kernel.asm
KERNEL_OBJ=kernel.o
KERNEL_BIN=kernel.bin

DEPEND = Makefile \
	defines.h \
	game.c game.h \
	imprimir.mac \
	kernel.asm \
	random.c random.h \
	screen.c screen.h \
	audio/audioplayer.c audio/audioplayer.h \
	audio/speaker.c audio/speaker.h \
	audio/tracks.asm \
	interrupts/idt.c interrupts/idt.h \
	interrupts/isr.asm interrupts/isr.h \
	interrupts/keyboard.c interrupts/keyboard.h \
	interrupts/pic.c interrupts/pic.h \
	interrupts/pit.c interrupts/pit.h \
	interrupts/rtc.c interrupts/rtc.h \
	mem/mmu.c mem/mmu.h \
	mem/gdt.c mem/gdt.h \
	tasks/sched.c tasks/sched.h \
	tasks/syscall.h \
	tasks/tss.c tasks/tss_asm.asm tasks/tss.h

AUDIO_TRACKS = audio/tracks/pacman_0.audio \
	       audio/tracks/spectra_0.audio \
	       audio/tracks/spectra_1.audio

OBJ=$(KERNEL_OBJ) \
	game.o \
	random.o \
	screen.o \
	audio/audioplayer.o \
	audio/speaker.o \
	audio/tracks.o \
	mem/gdt.o \
	interrupts/idt.o \
	interrupts/isr.o \
	interrupts/keyboard.o \
	interrupts/pic.o \
	interrupts/pit.o \
	interrupts/rtc.o \
	mem/mmu.o \
	tasks/sched.o \
	tasks/tss.o tasks/tss_asm.o

DISK_IMG=diskette.img
DISK_IMG_BZ=diskette.img.bz2

CFLAGS=-m32 -g -ggdb -Wall -Werror -Wno-char-subscripts -O0 \
  -fno-zero-initialized-in-bss -fno-stack-protector -ffreestanding


TASKIDLE=tasks/idle.tsk
TASKA=tasks/taskA.ctsk
TASKB=tasks/taskB.ctsk
TASKH=tasks/taskH.ctsk

TASKS=tasks/tareas.tsk

TASKSBINS=$(TASKIDLE) $(TASKA) $(TASKB) $(TASKH)

CODESIZE=60928    # = 65536 - 0x1200 = 64KB - 0x1200
TASKSSIZE=16384   # = 1 * (4096) + 3 * (4096) = idle + tareas
KERNELSIZE=77312  # = CODESIZE + TASKSSIZE

TASKSTARTADDR=0x40000000

CC=gcc
NASM=nasm
NASMFLAGS=-felf32
OBJCOPY=objcopy
NM=nm
LD=ld
LDTASKFLAGS=-s -static -m elf_i386 --oformat binary -b elf32-i386 -e task -Ttext $(TASKSTARTADDR)
LDFLAGS=-static -m elf_i386 -b elf32-i386 -e start -Ttext 0x1200

QUIET = @

.PHONY=clean all image tasks defines.h

all: pseudo_clean tasks image

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

%.o: %.asm
	$(NASM) $(NASMFLAGS) -o $@ $^

%.audio: $(shell echo $% | sed -e 's/_[0-9]*/.mid/')
	tools/frommidi.py $(shell echo $@ | sed -e 's/_[0-9]*.audio/.mid/') $@

kernel.bin: $(AUDIO_TRACKS) $(OBJ) $(TASKS)
	@echo 'Linkeando kernel...'
	$(LD) $(LDFLAGS) -o $@.tmp $(OBJ)
	$(NM) $@.tmp | grep -v " U " | awk '{print "0x" $$1 " " $$3}' > kernel.sym
	$(OBJCOPY) -S -O binary $@.tmp $@
	rm $@.tmp
	@echo ''

	@echo 'Generando imagen del kern.el...'
	mv kernel.bin kernel.bin.tmp
	dd if=/dev/zero of=kernel.bin bs=1 count=$(KERNELSIZE) conv=notrunc status=noxfer > /dev/null 2>&1
	dd if=kernel.bin.tmp of=kernel.bin bs=1 count=$(CODESIZE) conv=notrunc status=noxfer > /dev/null 2>&1
	dd if=$(TASKS) of=kernel.bin bs=1 count=$(TASKSSIZE) seek=$(CODESIZE) conv=notrunc status=noxfer > /dev/null 2>&1
	rm kernel.bin.tmp
	@echo ''

image: kernel.bin $(DEPEND) $(DISK_IMG)
	@echo 'Copiando el $(KERNEL_BIN) a la imagen de diskette'
	$(MCOPY) -o -i $(DISK_IMG) $(KERNEL_BIN) ::/
	@echo ''

$(DISK_IMG): $(DISK_IMG_BZ)
	bzip2 -dk $(DISK_IMG_BZ)

tasks/idle.tsk: tasks/idle.asm
	@echo 'Compilando tarea...'
	$(NASM) -fbin -o $@ $^
	@echo ''
	@echo 'Generando imagen de la tarea idle...'
	mv tasks/idle.tsk tasks/idle.tsk.tmp
	dd if=/dev/zero bs=1 count=4K of=$@ status=noxfer > /dev/null 2>&1
	dd if=$@.tmp bs=1 count=4K seek=0 conv=notrunc of=$@ status=noxfer > /dev/null 2>&1
	rm $@.tmp
	@echo ''

tasks/taskA.tsko: tasks/tareaA.c
	$(CC) $(CFLAGS) -c -o $@ $^
tasks/taskB.tsko: tasks/tareaB.c
	$(CC) $(CFLAGS) -c -o $@ $^
tasks/taskH.tsko: tasks/tareaH.c
	$(CC) $(CFLAGS) -c -o $@ $^

%.ctsk: %.tsko
	@echo 'Linkeando tarea...'
	$(LD) $(LDTASKFLAGS) -o $@.tmp $^
	@echo ''
	mv $@.tmp $@

tasks: $(TASKSBINS)
	@echo 'Generando imagen de las tareas...'
	$(QUIET) dd if=/dev/zero bs=1 count=$(TASKSSIZE) of=$(TASKS)  status=noxfer > /dev/null 2>&1
	$(QUIET) dd if=$(TASKIDLE) bs=1 count=4K of=$(TASKS) seek=0K  status=noxfer > /dev/null 2>&1
	$(QUIET) dd if=$(TASKA)    bs=1 count=4K of=$(TASKS) seek=4K  status=noxfer > /dev/null 2>&1
	$(QUIET) dd if=$(TASKB)    bs=1 count=4K of=$(TASKS) seek=8K  status=noxfer > /dev/null 2>&1
	$(QUIET) dd if=$(TASKH)    bs=1 count=4K of=$(TASKS) seek=12K status=noxfer > /dev/null 2>&1
	@echo ''

pseudo_clean:
	@echo 'Limpiando todo...'
	find . -name '*.o' -type f -exec rm -f "{}" \;
	rm -f *.bin
	rm -f *.tmp
	rm -f kernel.sym
	find . -name '*.ctsko' -type f -exec rm -f "{}" \;
	find . -name '*.ctsk' -type f -exec rm -f "{}" \;
	find . -name '*.tsko' -type f -exec rm -f "{}" \;
	find . -name '*.tsk' -type f -exec rm -f "{}" \;
	rm -f $(DISK_IMG)
	rm -rf *~
	@echo ''

clean: pseudo_clean
	@echo 'Limpiando mas cosas...'
	rm -f audio/tracks/*.audio
	@echo ''
