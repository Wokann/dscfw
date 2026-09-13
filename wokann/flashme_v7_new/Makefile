# Build all regional FlashMe V7 New packages.  Phat and Lite remain separate
# source trees because their firmware bases and patch layouts differ.
.DEFAULT_GOAL := all
.NOTPARALLEL:

.PHONY: all phat-ique lite-ique lite-kor
all: phat-ique lite-ique lite-kor

phat-ique:
	$(MAKE) -C phat_ique variants
lite-ique:
	$(MAKE) -C lite_ique variants
lite-kor:
	$(MAKE) -C lite_kor variants
