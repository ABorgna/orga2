
TASKA=taskA.ctsk
TASKB=taskB.ctsk

TASKSTARTADDR=0x40000000

NASM=nasm
NASMFLAGS=-felf32
LD=ld
LDTASKFLAGS=-s -static -m elf_i386 --oformat binary -b elf32-i386 -e task -Ttext $(TASKSTARTADDR)

QUIET = @

.PHONY=clean all

all: $(TASKA) $(TASKB)

taskA.tsko: fungi.asm
	$(NASM) $(NASMFLAGS) -o $@ -dTASK_A $^
taskB.tsko: fungi.asm
	$(NASM) $(NASMFLAGS) -o $@ -dTASK_B $^

%.ctsk: %.tsko
	@echo 'Linkeando tarea...'
	$(LD) $(LDTASKFLAGS) -o $@.tmp $^
	@echo ''
	mv $@.tmp $@

clean:
	rm -f *.ctsk
	rm -f *.tsko

