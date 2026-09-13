# Build every FlashMe reconstruction package from canonical official_v3.bin and
# official_v6.bin firmware inputs at this directory level.

FLASHME_ROOT := .
TOOLS_ROOT := ../tools
INCLUDE_ROOT := ../include
include $(INCLUDE_ROOT)/build-common.mk

.DEFAULT_GOAL := all
.NOTPARALLEL:

.PHONY: all \
	v1 v2 v3 v4 v5 v6 \
	v7-old-phat v7-new-phat v7-new-lite \
	v8-phat v8-lite v8a-phat v8a-lite

all: verify-official_inputs \
	v1 v3 v4 v5 v6 \
	v7-old-phat v7-new-phat v7-new-lite \
	v8-phat v8-lite v8a-phat v8a-lite

v1: verify-official_v3
	$(MAKE) -C v1 pack

# V2 is intentionally a diagnostic guard, not a build target.  Without this
# explicit rule, GNU make treats the retained v2/ documentation directory as
# an up-to-date target and reports a misleading success.
v2:
	@echo "FlashMe V2 is unavailable: no authenticated image or reliable technical source exists."
	@exit 1

v3: verify-official_v3
	$(MAKE) -C v3 pack

v4: verify-official_v3
	$(MAKE) -C v4 variants

v5: verify-official_v3
	$(MAKE) -C v5 variants

v6: verify-official_v3
	$(MAKE) -C v6 variants

v7-old-phat: verify-official_v3
	$(MAKE) -C v7_old/phat variants

v7-new-phat: verify-official_v3
	$(MAKE) -C v7_new/phat variants

v7-new-lite: verify-official_v6
	$(MAKE) -C v7_new/lite variants

v8-phat: verify-official_v3
	$(MAKE) -C v8/phat variants

v8-lite: verify-official_v6
	$(MAKE) -C v8/lite variants

v8a-phat: verify-official_v3
	$(MAKE) -C v8a/phat variants

v8a-lite: verify-official_v6
	$(MAKE) -C v8a/lite variants
