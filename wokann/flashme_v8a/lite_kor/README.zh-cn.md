# FlashMe V8a — KOR V1（Lite）

[English](README.md)

这是 Lite 源码包，只以 `official_kor_v1.bin` 构建。`make` 构建普通版；
`make variants` 构建 normal、stealth、noauto、stealth-noauto。

输出使用 `flashme_v8a_kor_v1` 前缀。镜像以 512 KiB 重新组装，FH 在 `0x7F680`、
用户设置在 `0x7FE00`；P1 RSA 验证被修改为通过，不保留 RSA 签名数据。
