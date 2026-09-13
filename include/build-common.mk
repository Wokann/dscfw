# Shared paths and verification rules for each FlashMe reconstruction package.
# A leaf Makefile sets FLASHME_ROOT relative to its own directory before include.

ifeq ($(OS),Windows_NT)
TOOL_EXEEXT := .exe
else
TOOL_EXEEXT :=
endif

ARMIPS ?= $(TOOLS_ROOT)/armips/armips$(TOOL_EXEEXT)
DSFWTOOL ?= $(TOOLS_ROOT)/dsfwtool/dsfwtool$(TOOL_EXEEXT)
CRC_TOOL ?= $(TOOLS_ROOT)/crc/flashmecrc$(TOOL_EXEEXT)
REPOSITORY_ROOT ?= $(INCLUDE_ROOT)/..
OFFICIAL_V3 ?= $(REPOSITORY_ROOT)/official_v3.bin
OFFICIAL_V6 ?= $(REPOSITORY_ROOT)/official_v6.bin

# Per-console Wi-Fi calibration and MAC-address bytes.  No other part of an
# image is normalized during validation.
OFFICIAL_PRIVATE_FILL_START := 0x28
OFFICIAL_PRIVATE_FILL_END := 0x170
OFFICIAL_V3_CRC32_END := 0x3F6F8
OFFICIAL_V3_CRC32_FILE := $(REPOSITORY_ROOT)/official_v3.crc32
OFFICIAL_V3_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V3_CRC32_FILE)))
OFFICIAL_V6_CRC32_END := 0x3F9B8
OFFICIAL_V6_CRC32_FILE := $(REPOSITORY_ROOT)/official_v6.crc32
OFFICIAL_V6_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V6_CRC32_FILE)))

.PHONY: crc-tool verify-official_v3 verify-official_v6 verify-official_inputs

crc-tool:
	$(MAKE) -C "$(TOOLS_ROOT)/crc"

verify-official_v3: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V3)" --range-end "$(OFFICIAL_V3_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V3_CRC32_EXPECTED)"

verify-official_v6: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V6)" --range-end "$(OFFICIAL_V6_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V6_CRC32_EXPECTED)"

verify-official_inputs: verify-official_v3 verify-official_v6

define DisplayFlashMeCrc
"$(CRC_TOOL)" crc16-record --image "$(1)" --range-end "$(2)"
endef

define CheckFlashMeCrc
"$(CRC_TOOL)" crc16-check --image "$(1)" --range-end "$(2)" --expected "$(3)"
endef
