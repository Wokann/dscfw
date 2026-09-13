# FlashMe V7 New — iQue V2（Lite）

[English](README.md)

这是 Lite 源码包，只以 `official_ique_v2.bin` 构建。运行 `make` 构建普通版；运行
`make variants` 构建普通版与 stealth。

输出为 `flashme_v7_new_ique_v2.bin`、`flashme_v7_new_ique_v2_stealth.bin`。镜像以
512 KiB 重新组装，FH 在 `0x7F680`、用户设置在 `0x7FE00`。P1 RSA 验证被修改为通过，
不保留 RSA 签名数据。
