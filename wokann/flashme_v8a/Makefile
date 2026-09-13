# Build all regional FlashMe V8a packages.  Phat and Lite are independent
# package trees and are deliberately not combined.
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
