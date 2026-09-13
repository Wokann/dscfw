# FlashMe V8a TV-out — iQue V2（Lite）

[English](README.md)

这是独立的 V8a Lite TV-out 源码包，只以 `official_ique_v2.bin` 构建。`make` 构建
普通版；`make variants` 构建 normal、stealth、noauto、stealth-noauto。输出遵循
`flashme_v8a_ique_v2_*_tvout.bin` 命名。

镜像以 512 KiB 重新组装，FH 在 `0x7F680`、用户设置在 `0x7FE00`；P1 RSA 验证被修改
为通过，不保留签名数据。
