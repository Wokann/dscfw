# TV-out is a separate V8a Lite package family; there is no Phat target.
.DEFAULT_GOAL := all
.NOTPARALLEL:

.PHONY: all lite-ique lite-kor
all: lite-ique lite-kor

lite-ique:
	$(MAKE) -C lite_ique variants
lite-kor:
	$(MAKE) -C lite_kor variants
