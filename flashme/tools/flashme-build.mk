# Shared paths and verification rules for each FlashMe reconstruction package.
# A leaf Makefile sets FLASHME_ROOT relative to its own directory before include.

ifeq ($(OS),Windows_NT)
TOOL_EXEEXT := .exe
else
TOOL_EXEEXT :=
endif

ARMIPS ?= $(FLASHME_ROOT)/tools/armips/armips$(TOOL_EXEEXT)
DSFWTOOL ?= $(FLASHME_ROOT)/tools/dsfwtool/dsfwtool$(TOOL_EXEEXT)
CRC_TOOL ?= $(FLASHME_ROOT)/tools/crc/flashmecrc$(TOOL_EXEEXT)
OFFICIAL_V3 ?= $(FLASHME_ROOT)/official_v3.bin
OFFICIAL_V6 ?= $(FLASHME_ROOT)/official_v6.bin
REFERENCE_ROOT ?= $(FLASHME_ROOT)/../extracted

OFFICIAL_PRIVATE_FILL_START := 0x2A
OFFICIAL_PRIVATE_FILL_END := 0x180
OFFICIAL_V3_CRC32_END := 0x3F6F8
OFFICIAL_V3_CRC32_EXPECTED := 0x96DF1D27
OFFICIAL_V6_CRC32_END := 0x3F9B8
OFFICIAL_V6_CRC32_EXPECTED := 0x594067E9

.PHONY: crc-tool verify-official_v3 verify-official_v6 verify-official_inputs

crc-tool:
	$(MAKE) -C "$(FLASHME_ROOT)/tools/crc"

verify-official_v3: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V3)" --range-end "$(OFFICIAL_V3_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V3_CRC32_EXPECTED)" --write "$(FLASHME_ROOT)/official_v3.crc32"

verify-official_v6: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V6)" --range-end "$(OFFICIAL_V6_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V6_CRC32_EXPECTED)" --write "$(FLASHME_ROOT)/official_v6.crc32"

verify-official_inputs: verify-official_v3 verify-official_v6

define VerifyFlashMe
"$(CRC_TOOL)" crc16-flashme --image "$(1)" --reference "$(2)" --range-end "$(3)" --expected "$(4)" --write "$(5)"
endef

define RecordFlashMe
"$(CRC_TOOL)" crc16-record --image "$(1)" --range-end "$(2)" --write "$(3)"
endef
