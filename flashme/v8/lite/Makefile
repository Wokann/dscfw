# FlashMe V8 Lite rebuild: official V6 -> plaintext temp -> plaintext build -> image.

ARMIPS ?= ../../armips.exe
DSFWTOOL ?= ../../dsfwtool.exe
OFFICIAL_V6 ?= official_v6.bin

TEMP_DIR := temp
BUILD_DIR := build
VARIANT ?= normal

ifeq ($(VARIANT),normal)
BUILD_STEALTH := 0
BUILD_NOAUTO := 0
OUTPUT := flashme_v8_lite.bin
FP1_OFFSET := 0x326A0
else ifeq ($(VARIANT),stealth)
BUILD_STEALTH := 1
BUILD_NOAUTO := 0
OUTPUT := flashme_v8_stealth_lite.bin
FP1_OFFSET := 0x32680
else ifeq ($(VARIANT),noauto)
BUILD_STEALTH := 0
BUILD_NOAUTO := 1
OUTPUT := flashme_v8_noauto_lite.bin
FP1_OFFSET := 0x32698
else ifeq ($(VARIANT),stealth-noauto)
BUILD_STEALTH := 1
BUILD_NOAUTO := 1
OUTPUT := flashme_v8_stealth_noauto_lite.bin
FP1_OFFSET := 0x32680
else
$(error VARIANT must be normal, stealth, noauto, or stealth-noauto)
endif

.PHONY: all unpack patch pack normal stealth noauto stealth-noauto variants

all: pack

unpack:
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V6) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -root . -definelabel BuildStealth $(BUILD_STEALTH) -definelabel BuildNoAuto $(BUILD_NOAUTO) src/main.s

pack: patch
	$(DSFWTOOL) -c $(OUTPUT) -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt --offset 0x180 $(BUILD_DIR)/p1.bin -p2 -comp -encrypt --offset 0x198 $(BUILD_DIR)/p2.bin -p3 -comp --p345-nearest-greedy --offset 0x183B8 $(BUILD_DIR)/p3.bin -p4 -comp --p345-nearest-greedy --offset 0x0F5A8 $(BUILD_DIR)/p4.bin -p5 -comp --p345-nearest-greedy --offset 0x2B8 $(BUILD_DIR)/p5.bin -fh --offset 0x3F680 $(BUILD_DIR)/fh.bin -fp1 -comp --offset $(FP1_OFFSET) $(BUILD_DIR)/fp1.bin -fp2 -comp --offset 0x29FE8 $(BUILD_DIR)/fp2.bin -b $(OFFICIAL_V6) -s 256K --fill FF

normal:
	$(MAKE) VARIANT=normal pack

stealth:
	$(MAKE) VARIANT=stealth pack

noauto:
	$(MAKE) VARIANT=noauto pack

stealth-noauto:
	$(MAKE) VARIANT=stealth-noauto pack

variants: normal stealth noauto stealth-noauto
