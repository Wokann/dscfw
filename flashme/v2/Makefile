# FlashMe V2 inferred reconstruction: official_v3.bin -> plaintext temp -> plaintext build -> image.

FLASHME_ROOT ?= ..
include $(FLASHME_ROOT)/tools/flashme-build.mk

TEMP_DIR := temp
BUILD_DIR := build
OUTPUT := flashme_v2_phat.bin
CRC16_END := 0x3FDFE
CRC16_FILE := $(basename $(OUTPUT)).crc16

.PHONY: all unpack patch pack

.DEFAULT_GOAL := all
all: pack

unpack: verify-official_v3
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V3) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -armimmediate max-imm8 -root . src/main.s

pack: patch
	# V2 inference choice: use V1 physical order P3 -> FP1 -> FP2.
	# Omit FP offsets so dsfwtool derives align8(P3_end)=0x29FA8 and align8(FP1_end)=0x36AC8.
	$(DSFWTOOL) -c $(OUTPUT) -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt --offset 0x180 $(BUILD_DIR)/p1.bin -p2 -comp -encrypt --offset 0x1A0 $(BUILD_DIR)/p2.bin -p3 -comp -flashme --offset 0x183B0 $(BUILD_DIR)/p3.bin -p4 -comp -flashme --offset 0x0F5B0 $(BUILD_DIR)/p4.bin -p5 -comp -flashme --offset 0x2C0 $(BUILD_DIR)/p5.bin -fh --offset 0x3FC80 $(BUILD_DIR)/fh.bin -fp1 -comp $(BUILD_DIR)/fp1.bin -fp2 -comp $(BUILD_DIR)/fp2.bin -s 256K --fill FF
	$(call RecordFlashMe,$(OUTPUT),$(CRC16_END),$(CRC16_FILE))
