# FlashMe V1 rebuild: official V3 -> plaintext temp -> plaintext build -> image.

ARMIPS ?= ../armips.exe
DSFWTOOL ?= ../dsfwtool.exe
OFFICIAL_V3 ?= official_v3.bin

TEMP_DIR := temp
BUILD_DIR := build
OUTPUT := flashme_v1.bin

.PHONY: all unpack patch pack

all: pack

unpack:
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V3) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -root . src/main.s

pack: patch
	$(DSFWTOOL) -c $(OUTPUT) -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt --offset 0x180 $(BUILD_DIR)/p1.bin -p2 -comp -encrypt --offset 0x1A0 $(BUILD_DIR)/p2.bin -p3 -comp -flashme --offset 0x183B0 $(BUILD_DIR)/p3.bin -p4 -comp -flashme --offset 0x0F5B0 $(BUILD_DIR)/p4.bin -p5 -comp -flashme --offset 0x2C0 $(BUILD_DIR)/p5.bin -fh --offset 0x3FC80 $(BUILD_DIR)/fh.bin -fp1 -comp --offset 0x29FA8 $(BUILD_DIR)/fp1.bin -fp2 -comp --offset 0x36AC8 $(BUILD_DIR)/fp2.bin -b $(OFFICIAL_V3) -s 256K --fill FF
