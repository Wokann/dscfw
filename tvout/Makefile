# Build all TV-out V8a Lite variants from the canonical official_v6.bin input.

FLASHME_ROOT := .
TOOLS_ROOT := ../tools
INCLUDE_ROOT := ../include
include $(INCLUDE_ROOT)/build-common.mk

.DEFAULT_GOAL := all
.NOTPARALLEL:

.PHONY: all v8a-lite

all: v8a-lite

v8a-lite: verify-official_v6
	$(MAKE) -C v8a/lite variants
