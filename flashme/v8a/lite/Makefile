# FlashMe V8a Lite rebuild: official_v6.bin -> plaintext temp -> plaintext build -> image.

FLASHME_ROOT ?= ../..
TOOLS_ROOT ?= $(FLASHME_ROOT)/../tools
INCLUDE_ROOT ?= $(FLASHME_ROOT)/../include
include $(INCLUDE_ROOT)/build-common.mk

TEMP_DIR := temp
BUILD_DIR := build
VARIANT ?= normal

ifeq ($(VARIANT),normal)
BUILD_STEALTH := 0
BUILD_NOAUTO := 0
OUTPUT := flashme_v8a_lite.bin
FP1_OFFSET := 0x328F8
CRC16_END := 0x3F800
else ifeq ($(VARIANT),stealth)
BUILD_STEALTH := 1
BUILD_NOAUTO := 0
OUTPUT := flashme_v8a_lite_stealth.bin
FP1_OFFSET := 0x328D8
CRC16_END := 0x3F800
else ifeq ($(VARIANT),noauto)
BUILD_STEALTH := 0
BUILD_NOAUTO := 1
OUTPUT := flashme_v8a_lite_noauto.bin
FP1_OFFSET := 0x328F0
CRC16_END := 0x3F800
else ifeq ($(VARIANT),stealth-noauto)
BUILD_STEALTH := 1
BUILD_NOAUTO := 1
OUTPUT := flashme_v8a_lite_stealth_noauto.bin
FP1_OFFSET := 0x328D0
CRC16_END := 0x3F800
else
$(error VARIANT must be normal, stealth, noauto, or stealth-noauto)
endif

CRC16_FILE := $(basename $(OUTPUT)).crc16
CRC16_EXPECTED := $(strip $(file <$(CRC16_FILE)))

.PHONY: all unpack patch pack normal stealth noauto stealth-noauto variants

.DEFAULT_GOAL := all
all: pack

unpack: verify-official_v6
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V6) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -armimmediate max-imm8 -root . -definelabel BuildStealth $(BUILD_STEALTH) -definelabel BuildNoAuto $(BUILD_NOAUTO) src/main.s

pack: patch
	$(DSFWTOOL) -c $(OUTPUT) -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt --offset 0x180 $(BUILD_DIR)/p1.bin -p2 -comp -encrypt --offset 0x270 $(BUILD_DIR)/p2.bin -p3 -comp -flashme --offset 0x18610 $(BUILD_DIR)/p3.bin -p4 -comp -flashme --offset 0x0F800 $(BUILD_DIR)/p4.bin -p5 -comp -flashme --offset 0x510 $(BUILD_DIR)/p5.bin -fh --offset 0x3F680 $(BUILD_DIR)/fh.bin -fp1 -comp --offset $(FP1_OFFSET) $(BUILD_DIR)/fp1.bin -fp2 -comp --offset 0x2A240 $(BUILD_DIR)/fp2.bin -s 256K --fill FF
	$(call CheckFlashMeCrc,$(OUTPUT),$(CRC16_END),$(CRC16_EXPECTED))

normal:
	$(MAKE) VARIANT=normal pack

stealth:
	$(MAKE) VARIANT=stealth pack

noauto:
	$(MAKE) VARIANT=noauto pack

stealth-noauto:
	$(MAKE) VARIANT=stealth-noauto pack

variants: normal stealth noauto stealth-noauto
