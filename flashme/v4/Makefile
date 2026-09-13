# FlashMe V4 rebuild: official_v3.bin -> plaintext temp -> plaintext build -> image.

FLASHME_ROOT ?= ..
TOOLS_ROOT ?= $(FLASHME_ROOT)/../tools
INCLUDE_ROOT ?= $(FLASHME_ROOT)/../include
include $(INCLUDE_ROOT)/build-common.mk

TEMP_DIR := temp
BUILD_DIR := build
VARIANT ?= normal
FIX_FH ?= 0
FH_OFFSET := 0x3FC80

ifneq ($(FIX_FH),0)
ifneq ($(FIX_FH),1)
$(error FIX_FH must be 0 or 1)
endif
endif

ifeq ($(VARIANT),normal)
BUILD_STEALTH := 0
OUTPUT_BASE := flashme_v4_phat
FP1_OFFSET := 0x323D0
CRC16_END := 0x3FDFE
else ifeq ($(VARIANT),stealth)
BUILD_STEALTH := 1
OUTPUT_BASE := flashme_v4_phat_stealth
FP1_OFFSET := 0x32390
CRC16_END := 0x3FDFE
else
$(error VARIANT must be normal or stealth)
endif

ifeq ($(FIX_FH),1)
OUTPUT := $(OUTPUT_BASE)_fix_fh.bin
FH_OFFSET := 0x3F680
else
OUTPUT := $(OUTPUT_BASE).bin
CRC16_FILE := $(basename $(OUTPUT)).crc16
CRC16_EXPECTED := $(strip $(file <$(CRC16_FILE)))
endif

.PHONY: all unpack patch pack normal stealth variants fix_fh

.DEFAULT_GOAL := all
all: pack

unpack: verify-official_v3
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V3) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -armimmediate max-imm8 -root . -definelabel BuildStealth $(BUILD_STEALTH) -definelabel FIX_FH $(FIX_FH) src/main.s

pack: patch
	$(DSFWTOOL) -c $(OUTPUT) --layout layout.ld -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt $(BUILD_DIR)/p1.bin -p2 -comp -encrypt $(BUILD_DIR)/p2.bin -p3 -comp -flashme $(BUILD_DIR)/p3.bin -p4 -comp -flashme $(BUILD_DIR)/p4.bin -p5 -comp -flashme $(BUILD_DIR)/p5.bin -fh $(BUILD_DIR)/fh.bin -fp1 -comp $(BUILD_DIR)/fp1.bin -fp2 -comp $(BUILD_DIR)/fp2.bin -s 256K --fill FF
	$(if $(filter 0,$(FIX_FH)),$(call CheckFlashMeCrc,$(OUTPUT),$(CRC16_END),$(CRC16_EXPECTED)),$(call DisplayFlashMeCrc,$(OUTPUT),$(CRC16_END)))

normal:
	$(MAKE) VARIANT=normal pack

stealth:
	$(MAKE) VARIANT=stealth pack

fix_fh:
	$(MAKE) VARIANT=$(VARIANT) FIX_FH=1 pack

variants: normal stealth
