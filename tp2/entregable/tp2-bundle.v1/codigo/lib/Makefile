# ************************************************************************* #
# Organizacion del Computador II                                            #
#                                                                           #
#   Trabajo Practico 2                                                      #
#                                                                           #
# ************************************************************************* #
ASM = nasm
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	ASMFLAGS64 = -felf64 -g -F dwarf
endif
ifeq ($(UNAME_S),Darwin)
	ASMFLAGS64 = -fmacho64 -g -DDARWIN
endif

ASMFLAGS = $(ASMFLAGS64)

CFLAGS64 ?=-Wall -Wextra -pedantic -O0 -ggdb
CFLAGS=$(CFLAGS64)

BUILD_DIR = ../build

LIBS = copyN

LIBS_OBJ = $(addsuffix .o, $(LIBS))
LIBS_OBJ_CON_PATH = $(addprefix  $(BUILD_DIR)/, $(LIBS_OBJ))

.PHONY: libs clean

libs: $(LIBS_OBJ_CON_PATH)

$(BUILD_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: %.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	rm -f $(LIBS_OBJ_CON_PATH)
