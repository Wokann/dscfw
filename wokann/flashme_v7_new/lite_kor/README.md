# FlashMe V7 New — Korean V1 (Lite)

[简体中文](README.zh-cn.md)

This is the Lite source package and builds only from `official_kor_v1.bin`.
Run `make` for normal, or `make variants` for normal and stealth.

Outputs: `flashme_v7_new_kor_v1.bin` and
`flashme_v7_new_kor_v1_stealth.bin`.  Images are newly assembled as 512 KiB
with FH at `0x7F680` and user settings at `0x7FE00`.  P1 RSA validation is
patched to accept, so no RSA signature data is preserved.
