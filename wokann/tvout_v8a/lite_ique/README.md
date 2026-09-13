# FlashMe V8a TV-out — iQue V2 (Lite)

[简体中文](README.zh-cn.md)

This is the separate V8a Lite TV-out package; it builds only from
`official_ique_v2.bin`.  Run `make` for normal, or `make variants` for normal,
stealth, noauto, and stealth-noauto.  Outputs use the
`flashme_v8a_ique_v2_*_tvout.bin` naming pattern.

The image is freshly assembled as 512 KiB, with FH at `0x7F680`, user settings
at `0x7FE00`, and P1 RSA checks patched to accept without signature retention.
