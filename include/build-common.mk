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

# Per-console Wi-Fi calibration and MAC-address bytes.  No other part of an
# image is normalized during validation.  Each CRC32_END is the half-open end
# of the packed primary-component area: max(Pn offset + align_up(Pn effective
# stream size, Pn alignment)).  It is deliberately not the image capacity.
OFFICIAL_PRIVATE_FILL_START := 0x28
OFFICIAL_PRIVATE_FILL_END := 0x170

OFFICIAL_V1 ?= $(REPOSITORY_ROOT)/official_v1.bin
OFFICIAL_V1_CRC32_END := 0x3F6F8
OFFICIAL_V1_CRC32_FILE := $(REPOSITORY_ROOT)/official_v1.crc32
OFFICIAL_V1_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V1_CRC32_FILE)))

OFFICIAL_V2 ?= $(REPOSITORY_ROOT)/official_v2.bin
OFFICIAL_V2_CRC32_END := 0x3F6D0
OFFICIAL_V2_CRC32_FILE := $(REPOSITORY_ROOT)/official_v2.crc32
OFFICIAL_V2_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V2_CRC32_FILE)))

OFFICIAL_V3 ?= $(REPOSITORY_ROOT)/official_v3.bin
OFFICIAL_V3_CRC32_END := 0x3F6F8
OFFICIAL_V3_CRC32_FILE := $(REPOSITORY_ROOT)/official_v3.crc32
OFFICIAL_V3_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V3_CRC32_FILE)))

OFFICIAL_V4 ?= $(REPOSITORY_ROOT)/official_v4.bin
OFFICIAL_V4_CRC32_END := 0x3F7B0
OFFICIAL_V4_CRC32_FILE := $(REPOSITORY_ROOT)/official_v4.crc32
OFFICIAL_V4_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V4_CRC32_FILE)))

OFFICIAL_V5 ?= $(REPOSITORY_ROOT)/official_v5.bin
OFFICIAL_V5_CRC32_END := 0x3F7B8
OFFICIAL_V5_CRC32_FILE := $(REPOSITORY_ROOT)/official_v5.crc32
OFFICIAL_V5_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V5_CRC32_FILE)))

OFFICIAL_V6 ?= $(REPOSITORY_ROOT)/official_v6.bin
OFFICIAL_V6_CRC32_END := 0x3F9B8
OFFICIAL_V6_CRC32_FILE := $(REPOSITORY_ROOT)/official_v6.crc32
OFFICIAL_V6_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V6_CRC32_FILE)))

OFFICIAL_V7 ?= $(REPOSITORY_ROOT)/official_v7.bin
OFFICIAL_V7_CRC32_END := 0x3F760
OFFICIAL_V7_CRC32_FILE := $(REPOSITORY_ROOT)/official_v7.crc32
OFFICIAL_V7_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_V7_CRC32_FILE)))

OFFICIAL_IQUE_V1 ?= $(REPOSITORY_ROOT)/official_ique_v1.bin
OFFICIAL_IQUE_V1_CRC32_END := 0x5A1A8
OFFICIAL_IQUE_V1_CRC32_FILE := $(REPOSITORY_ROOT)/official_ique_v1.crc32
OFFICIAL_IQUE_V1_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_IQUE_V1_CRC32_FILE)))

OFFICIAL_IQUE_V2 ?= $(REPOSITORY_ROOT)/official_ique_v2.bin
OFFICIAL_IQUE_V2_CRC32_END := 0x5A1A0
OFFICIAL_IQUE_V2_CRC32_FILE := $(REPOSITORY_ROOT)/official_ique_v2.crc32
OFFICIAL_IQUE_V2_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_IQUE_V2_CRC32_FILE)))

OFFICIAL_KOR_V1 ?= $(REPOSITORY_ROOT)/official_kor_v1.bin
OFFICIAL_KOR_V1_CRC32_END := 0x44E50
OFFICIAL_KOR_V1_CRC32_FILE := $(REPOSITORY_ROOT)/official_kor_v1.crc32
OFFICIAL_KOR_V1_CRC32_EXPECTED := $(strip $(file <$(OFFICIAL_KOR_V1_CRC32_FILE)))

.PHONY: crc-tool verify-official_v1 verify-official_v2 verify-official_v3 verify-official_v4 verify-official_v5 verify-official_v6 verify-official_v7 verify-official_ique_v1 verify-official_ique_v2 verify-official_kor_v1 verify-official_inputs

crc-tool:
	$(MAKE) -C "$(TOOLS_ROOT)/crc"

verify-official_v1: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V1)" --range-end "$(OFFICIAL_V1_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V1_CRC32_EXPECTED)"

verify-official_v2: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V2)" --range-end "$(OFFICIAL_V2_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V2_CRC32_EXPECTED)"

verify-official_v3: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V3)" --range-end "$(OFFICIAL_V3_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V3_CRC32_EXPECTED)"

verify-official_v4: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V4)" --range-end "$(OFFICIAL_V4_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V4_CRC32_EXPECTED)"

verify-official_v5: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V5)" --range-end "$(OFFICIAL_V5_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V5_CRC32_EXPECTED)"

verify-official_v6: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V6)" --range-end "$(OFFICIAL_V6_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V6_CRC32_EXPECTED)"

verify-official_v7: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_V7)" --range-end "$(OFFICIAL_V7_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_V7_CRC32_EXPECTED)"

verify-official_ique_v1: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_IQUE_V1)" --range-end "$(OFFICIAL_IQUE_V1_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_IQUE_V1_CRC32_EXPECTED)"

verify-official_ique_v2: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_IQUE_V2)" --range-end "$(OFFICIAL_IQUE_V2_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_IQUE_V2_CRC32_EXPECTED)"

verify-official_kor_v1: crc-tool
	"$(CRC_TOOL)" crc32-official --image "$(OFFICIAL_KOR_V1)" --range-end "$(OFFICIAL_KOR_V1_CRC32_END)" --private-fill-start "$(OFFICIAL_PRIVATE_FILL_START)" --private-fill-end "$(OFFICIAL_PRIVATE_FILL_END)" --expected "$(OFFICIAL_KOR_V1_CRC32_EXPECTED)"

verify-official_inputs: verify-official_v1 verify-official_v2 verify-official_v3 verify-official_v4 verify-official_v5 verify-official_v6 verify-official_v7 verify-official_ique_v1 verify-official_ique_v2 verify-official_kor_v1

define DisplayFlashMeCrc
"$(CRC_TOOL)" crc16-record --image "$(1)" --range-end "$(2)"
endef

define CheckFlashMeCrc
"$(CRC_TOOL)" crc16-check --image "$(1)" --range-end "$(2)" --expected "$(3)"
endef
