# FlashMe V8a Lite iQue TV-out rebuild: official_ique_v2.bin -> plaintext temp -> plaintext build -> 512 KiB image.

FLASHME_ROOT ?= ../..
TOOLS_ROOT ?= $(FLASHME_ROOT)/../tools
INCLUDE_ROOT ?= $(FLASHME_ROOT)/../include
include $(INCLUDE_ROOT)/build-common.mk

TEMP_DIR := temp
BUILD_DIR := build
VARIANT ?= normal
CRC16_END := 0x7F800
LAYOUT_FILE := layout.ld

ifeq ($(VARIANT),normal)
BUILD_STEALTH := 0
BUILD_NOAUTO := 0
OUTPUT := flashme_v8a_lite_ique.bin
else ifeq ($(VARIANT),stealth)
BUILD_STEALTH := 1
BUILD_NOAUTO := 0
OUTPUT := flashme_v8a_lite_ique_stealth.bin
else ifeq ($(VARIANT),noauto)
BUILD_STEALTH := 0
BUILD_NOAUTO := 1
OUTPUT := flashme_v8a_lite_ique_noauto.bin
else ifeq ($(VARIANT),stealth-noauto)
BUILD_STEALTH := 1
BUILD_NOAUTO := 1
OUTPUT := flashme_v8a_lite_ique_stealth_noauto.bin
else
$(error VARIANT must be normal, stealth, noauto, or stealth-noauto)
endif

OUTPUT := $(basename $(OUTPUT))_tvout.bin
FP2_COMPRESS := -comp -tvout

# Unlike the archived international Lite noauto TV-out image, these regional
# builds have no fixed reference image to preserve.  Every variant is packed
# as an independent FF-filled image using its declarative auto layout.

.PHONY: all unpack patch pack normal stealth noauto stealth-noauto variants

.DEFAULT_GOAL := all
all: pack

unpack: verify-official_ique_v2
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_IQUE_V2) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -armimmediate max-imm8 -root . -definelabel BuildStealth $(BUILD_STEALTH) -definelabel BuildNoAuto $(BUILD_NOAUTO) -definelabel BuildTvOut 1 src/main.s

pack: patch
	$(DSFWTOOL) -c $(OUTPUT) --layout $(LAYOUT_FILE) -h $(BUILD_DIR)/h.bin -p1 -comp -encrypt $(BUILD_DIR)/p1.bin -p2 -comp -encrypt $(BUILD_DIR)/p2.bin -p3 -comp -flashme $(BUILD_DIR)/p3.bin -p4 -comp -flashme $(BUILD_DIR)/p4.bin -p5 -comp -flashme $(BUILD_DIR)/p5.bin -fh $(BUILD_DIR)/fh.bin -fp1 -comp $(BUILD_DIR)/fp1.bin -fp2 $(FP2_COMPRESS) $(BUILD_DIR)/fp2.bin -s 512K --fill FF
	$(call DisplayFlashMeCrc,$(OUTPUT),$(CRC16_END))

normal:
	$(MAKE) VARIANT=normal pack

stealth:
	$(MAKE) VARIANT=stealth pack

noauto:
	$(MAKE) VARIANT=noauto pack

stealth-noauto:
	$(MAKE) VARIANT=stealth-noauto pack

variants: normal stealth noauto stealth-noauto
