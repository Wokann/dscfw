# FlashMe V7 New — iQue V1 (Phat)

[简体中文](README.zh-cn.md)

This is the Phat source package.  It builds from `official_ique_v1.bin`, not
from a Lite or international firmware base.

Run `make` for the normal image, or `make variants` for normal and stealth.
The outputs are `flashme_v7_new_ique_v1.bin` and
`flashme_v7_new_ique_v1_stealth.bin`.

Images are freshly assembled as 512 KiB.  The FlashMe header is at `0x7F680`,
user settings are at `0x7FE00`, and the P1 RSA validation entries are patched
to accept; no original RSA signature block is retained.
