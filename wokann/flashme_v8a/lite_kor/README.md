# FlashMe V8a — Korean V1 (Lite)

[简体中文](README.zh-cn.md)

This Lite package builds only from `official_kor_v1.bin`.  Run `make` for
normal, or `make variants` for normal, stealth, noauto, and stealth-noauto.

Outputs use the `flashme_v8a_kor_v1` prefix.  Images are freshly assembled as
512 KiB, with FH at `0x7F680` and user settings at `0x7FE00`; P1 RSA validation
is patched to accept without retaining RSA signature data.
