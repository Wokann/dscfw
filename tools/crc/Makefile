# Dependency-free CRC checker used by the FlashMe reconstruction Makefiles.

CC ?= cc
CFLAGS ?= -O2 -std=c99 -Wall -Wextra -Wpedantic
CPPFLAGS ?=
LDFLAGS ?=

ifeq ($(OS),Windows_NT)
EXEEXT := .exe
LDFLAGS += -static
else
EXEEXT :=
endif

TARGET := flashmecrc$(EXEEXT)

.PHONY: all clean

all: $(TARGET)

$(TARGET): flashmecrc.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f flashmecrc flashmecrc.exe
