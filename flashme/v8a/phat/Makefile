# FlashMe V8a Phat: official V3 -> plaintext components -> rebuilt firmware.

ARMIPS ?= ../../armips.exe
DSFWTOOL ?= ../../dsfwtool.exe
OFFICIAL_V3 ?= official_v3.bin

TEMP_DIR := temp
BUILD_DIR := build
VARIANT ?= normal

ifeq ($(VARIANT),normal)
BUILD_STEALTH := 0
BUILD_NOAUTO := 0
OUTPUT := flashme_v8a_phat.bin
FP1_OFFSET := 0x32718
else ifeq ($(VARIANT),stealth)
BUILD_STEALTH := 1
BUILD_NOAUTO := 0
OUTPUT := flashme_v8a_stealth_phat.bin
FP1_OFFSET := 0x326D8
else ifeq ($(VARIANT),noauto)
BUILD_STEALTH := 0
BUILD_NOAUTO := 1
OUTPUT := flashme_v8a_noauto_phat.bin
FP1_OFFSET := 0x32708
else ifeq ($(VARIANT),stealth-noauto)
BUILD_STEALTH := 1
BUILD_NOAUTO := 1
OUTPUT := flashme_v8a_stealth_noauto_phat.bin
FP1_OFFSET := 0x326D0
else
$(error VARIANT must be normal, stealth, noauto, or stealth-noauto)
endif

.PHONY: all unpack patch pack normal stealth noauto stealth-noauto variants

all: pack

unpack:
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V3) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -armimmediate max-imm8 -root . -definelabel BuildStealth $(BUILD_STEALTH) -definelabel BuildNoAuto $(BUILD_NOAUTO) src/main.s

pack: patch
	$(DSFWTOOL) -c $(OUTPUT) -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt --offset 0x180 $(BUILD_DIR)/p1.bin -p2 -comp -encrypt --offset 0x270 $(BUILD_DIR)/p2.bin -p3 -comp -flashme --offset 0x18600 $(BUILD_DIR)/p3.bin -p4 -comp -flashme --offset 0x0F800 $(BUILD_DIR)/p4.bin -p5 -comp -flashme --offset 0x510 $(BUILD_DIR)/p5.bin -fh --offset 0x3F680 $(BUILD_DIR)/fh.bin -fp1 -comp --offset $(FP1_OFFSET) $(BUILD_DIR)/fp1.bin -fp2 -comp --offset 0x2A1F8 $(BUILD_DIR)/fp2.bin -s 256K --fill FF

normal:
	$(MAKE) VARIANT=normal pack

stealth:
	$(MAKE) VARIANT=stealth pack

noauto:
	$(MAKE) VARIANT=noauto pack

stealth-noauto:
	$(MAKE) VARIANT=stealth-noauto pack

variants: normal stealth noauto stealth-noauto
