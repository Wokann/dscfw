# FlashMe V8a Lite rebuild: official_v6.bin -> plaintext temp -> plaintext build -> image.

FLASHME_ROOT ?= ../..
TOOLS_ROOT ?= $(FLASHME_ROOT)/../tools
INCLUDE_ROOT ?= $(FLASHME_ROOT)/../include
include $(INCLUDE_ROOT)/build-common.mk

TEMP_DIR := temp
BUILD_DIR := build
VARIANT ?= normal
CRC16_END := 0x3F800
LAYOUT_FILE := layout.ld

ifeq ($(VARIANT),normal)
BUILD_STEALTH := 0
BUILD_NOAUTO := 0
OUTPUT := flashme_v8a_lite.bin
else ifeq ($(VARIANT),stealth)
BUILD_STEALTH := 1
BUILD_NOAUTO := 0
OUTPUT := flashme_v8a_lite_stealth.bin
else ifeq ($(VARIANT),noauto)
BUILD_STEALTH := 0
BUILD_NOAUTO := 1
OUTPUT := flashme_v8a_lite_noauto.bin
CRC16_FILE := flashme_v8a_lite_noauto_tvout.crc16
CRC16_EXPECTED := $(strip $(file <$(CRC16_FILE)))
LAYOUT_FILE := layout.noauto.ld
else ifeq ($(VARIANT),stealth-noauto)
BUILD_STEALTH := 1
BUILD_NOAUTO := 1
OUTPUT := flashme_v8a_lite_stealth_noauto.bin
else
$(error VARIANT must be normal, stealth, noauto, or stealth-noauto)
endif

BASE_DIR := $(FLASHME_ROOT)/../flashme/v8a/lite
BASE_OUTPUT := $(BASE_DIR)/$(OUTPUT)
OUTPUT := $(basename $(OUTPUT))_tvout.bin
FP2_COMPRESS := -comp -tvout

# Only the archived Lite noauto TV-out image has an official fixed CRC16
# reference.  Its IPS delta leaves bytes after the shorter FP2 stream from the
# non-TV-out base, so reproduce that one with base preservation.  The other
# three local variants are ordinary fresh images: use FF fill plus normal
# effective-stream zero padding, without a base-image dependency.
ifeq ($(VARIANT),noauto)
PACK_PREREQUISITE := base
PACK_BASE_OPTIONS := -b $(BASE_OUTPUT) --no-stream-padding
PACK_HEADER_OPTION :=
else
PACK_PREREQUISITE :=
PACK_BASE_OPTIONS :=
PACK_HEADER_OPTION := -h $(BUILD_DIR)/h.bin
endif

.PHONY: all base unpack patch pack normal stealth noauto stealth-noauto variants

.DEFAULT_GOAL := all
all: pack

# The noauto pack prerequisite rebuilds this byte-identical non-TV-out base.
# Its -b path preserves bytes outside explicit TV-out component streams.
base:
	$(MAKE) -C $(BASE_DIR) VARIANT=$(VARIANT) pack

unpack: verify-official_v6
	mkdir -p $(TEMP_DIR) $(BUILD_DIR)
	$(DSFWTOOL) -x $(OFFICIAL_V6) -h $(TEMP_DIR)/h.bin -p1 -decrypt -uncomp $(TEMP_DIR)/p1.bin -p2 -decrypt -uncomp $(TEMP_DIR)/p2.bin -p3 -uncomp $(TEMP_DIR)/p3.bin -p4 -uncomp $(TEMP_DIR)/p4.bin -p5 -uncomp $(TEMP_DIR)/p5.bin

patch: unpack
	$(ARMIPS) -armimmediate max-imm8 -root . -definelabel BuildStealth $(BUILD_STEALTH) -definelabel BuildNoAuto $(BUILD_NOAUTO) -definelabel BuildTvOut 1 src/main.s

pack: $(PACK_PREREQUISITE) patch
	$(DSFWTOOL) -c $(OUTPUT) --layout $(LAYOUT_FILE) $(PACK_BASE_OPTIONS) $(PACK_HEADER_OPTION) -p1 -comp -encrypt $(BUILD_DIR)/p1.bin -p2 -comp -encrypt $(BUILD_DIR)/p2.bin -p3 -comp -flashme $(BUILD_DIR)/p3.bin -p4 -comp -flashme $(BUILD_DIR)/p4.bin -p5 -comp -flashme $(BUILD_DIR)/p5.bin -fh $(BUILD_DIR)/fh.bin -fp1 -comp $(BUILD_DIR)/fp1.bin -fp2 $(FP2_COMPRESS) $(BUILD_DIR)/fp2.bin -s 256K --fill FF
	$(if $(filter noauto,$(VARIANT)),$(call CheckFlashMeCrc,$(OUTPUT),$(CRC16_END),$(CRC16_EXPECTED)),$(call DisplayFlashMeCrc,$(OUTPUT),$(CRC16_END)))

normal:
	$(MAKE) VARIANT=normal pack

stealth:
	$(MAKE) VARIANT=stealth pack

noauto:
	$(MAKE) VARIANT=noauto pack

stealth-noauto:
	$(MAKE) VARIANT=stealth-noauto pack

variants: normal stealth noauto stealth-noauto
