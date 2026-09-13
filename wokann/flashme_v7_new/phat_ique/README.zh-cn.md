# FlashMe V7 New — iQue V1（Phat）

[English](README.md)

这是 Phat 源码包，只以 `official_ique_v1.bin` 构建，不使用 Lite 或国际版固件基底。

运行 `make` 构建普通版；运行 `make variants` 构建普通版与 stealth。输出为
`flashme_v7_new_ique_v1.bin`、`flashme_v7_new_ique_v1_stealth.bin`。

镜像以 512 KiB 重新组装；FH 位于 `0x7F680`，用户设置位于 `0x7FE00`。P1 的 RSA
验证入口被修改为通过，不保留原始 RSA 签名区数据。
