# FlashMe V3 rebuild: official_v3.bin -> plaintext temp -> plaintext build -> image.

FLASHME_ROOT ?= ..
TOOLS_ROOT ?= $(FLASHME_ROOT)/../tools
INCLUDE_ROOT ?= $(FLASHME_ROOT)/../include
include $(INCLUDE_ROOT)/build-common.mk

TEMP_DIR := temp
BUILD_DIR := build
FIX_FH ?= 0
FH_OFFSET := 0x3FC80

ifneq ($(FIX_FH),0)
ifneq ($(FIX_FH),1)
$(error FIX_FH must be 0 or 1)
endif
endif

ifeq ($(FIX_FH),1)
OUTPUT := flashme_v3_phat_fix_fh.bin
FH_OFFSET := 0x3F680
else
OUTPUT := flashme_v3_phat.bin
CRC16_FILE := $(basename $(OUTPUT)).crc16
CRC16_EXPECTED := $(strip $(file <$(CRC16_FILE)))
endif

CRC16_END := 0x3FDFE

.PHONY: all unpack patch pack fix_fh

.DEFAULT_GOAL := all
all: pack

unpack: verify-official_v3
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V3) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -armimmediate max-imm8 -root . -definelabel FIX_FH $(FIX_FH) src/main.s

pack: patch
	$(DSFWTOOL) -c $(OUTPUT) -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt --offset 0x180 $(BUILD_DIR)/p1.bin -p2 -comp -encrypt --offset 0x1A0 $(BUILD_DIR)/p2.bin -p3 -comp -flashme --offset 0x183B0 $(BUILD_DIR)/p3.bin -p4 -comp -flashme --offset 0x0F5B0 $(BUILD_DIR)/p4.bin -p5 -comp -flashme --offset 0x2C0 $(BUILD_DIR)/p5.bin -fh --offset $(FH_OFFSET) $(BUILD_DIR)/fh.bin -fp1 -comp --offset 0x323B0 $(BUILD_DIR)/fp1.bin -fp2 -comp --offset 0x29FA8 $(BUILD_DIR)/fp2.bin -s 256K --fill FF
	$(if $(filter 0,$(FIX_FH)),$(call CheckFlashMeCrc,$(OUTPUT),$(CRC16_END),$(CRC16_EXPECTED)),$(call DisplayFlashMeCrc,$(OUTPUT),$(CRC16_END)))

fix_fh:
	$(MAKE) FIX_FH=1 pack
