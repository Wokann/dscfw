# FlashMe V4 rebuild: official_v3.bin -> plaintext temp -> plaintext build -> image.

FLASHME_ROOT ?= ..
include $(FLASHME_ROOT)/tools/flashme-build.mk

TEMP_DIR := temp
BUILD_DIR := build
VARIANT ?= normal

ifeq ($(VARIANT),normal)
BUILD_STEALTH := 0
OUTPUT := flashme_v4_phat.bin
FP1_OFFSET := 0x323D0
REFERENCE := $(REFERENCE_ROOT)/flashme_v4_phat.bin
CRC16_END := 0x3FDFE
CRC16_EXPECTED := 0xE316
else ifeq ($(VARIANT),stealth)
BUILD_STEALTH := 1
OUTPUT := flashme_v4_phat_stealth.bin
FP1_OFFSET := 0x32390
REFERENCE := $(REFERENCE_ROOT)/flashme_v4_phat_stealth.bin
CRC16_END := 0x3FDFE
CRC16_EXPECTED := 0xB864
else
$(error VARIANT must be normal or stealth)
endif

CRC16_FILE := $(basename $(OUTPUT)).crc16

.PHONY: all unpack patch pack normal stealth variants

.DEFAULT_GOAL := all
all: pack

unpack: verify-official_v3
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V3) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -armimmediate max-imm8 -root . -definelabel BuildStealth $(BUILD_STEALTH) src/main.s

pack: patch
	$(DSFWTOOL) -c $(OUTPUT) -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt --offset 0x180 $(BUILD_DIR)/p1.bin -p2 -comp -encrypt --offset 0x1A0 $(BUILD_DIR)/p2.bin -p3 -comp -flashme --offset 0x183B0 $(BUILD_DIR)/p3.bin -p4 -comp -flashme --offset 0x0F5B0 $(BUILD_DIR)/p4.bin -p5 -comp -flashme --offset 0x2C0 $(BUILD_DIR)/p5.bin -fh --offset 0x3FC80 $(BUILD_DIR)/fh.bin -fp1 -comp --offset $(FP1_OFFSET) $(BUILD_DIR)/fp1.bin -fp2 -comp --offset 0x29FA8 $(BUILD_DIR)/fp2.bin -s 256K --fill FF
	$(call VerifyFlashMe,$(OUTPUT),$(REFERENCE),$(CRC16_END),$(CRC16_EXPECTED),$(CRC16_FILE))

normal:
	$(MAKE) VARIANT=normal pack

stealth:
	$(MAKE) VARIANT=stealth pack

variants: normal stealth
