CC=c99
CFLAGS=-Wall -Wextra -pedantic -O0 -ggdb -lm -Wno-unused-parameter
NASM=nasm
NASMFLAGS=-f elf64 -g -F DWARF

all: main tester

main: main.c tdt_c.o tdt_asm.o
	$(CC) $(CFLAGS) $^ -o $@

tester: tester.c tdt_c.o tdt_asm.o
	$(CC) $(CFLAGS) $^ -o $@

tdt_asm.o: tdt.asm
	$(NASM) $(NASMFLAGS) $< -o $@

tdt_c.o: tdt.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o
	rm -f main tester
	rm -f salida.caso.*
