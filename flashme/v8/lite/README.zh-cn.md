# FlashMe V8 Lite 构建包

[English](README.md)

## 声明

本包仅包含 ARMIPS 源代码与 CRC 参考记录，不分发任天堂固件镜像或原始 FlashMe 镜像。

## 构建

将 <code>official_v6.bin</code> 放入 <code>flashme/</code> 根目录后，在本目录运行
<code>make</code>。
如需构建表中全部变体，运行 <code>make variants</code>。

## CRC-16/IBM

每次构建都会校验 <code>[0x000000, 0x3F800)</code> 范围。UTF-8
<code>*.crc16</code> 文件保存对应参考值。

| 变体 | 输出 | CRC 记录 | CRC-16 |
| --- | --- | --- | --- |
| <code>noauto</code> | <code>flashme_v8_lite_noauto.bin</code> | <code>flashme_v8_lite_noauto.crc16</code> | <code>0xAF7B</code> |
| <code>stealth_noauto</code> | <code>flashme_v8_lite_stealth_noauto.bin</code> | <code>flashme_v8_lite_stealth_noauto.crc16</code> | <code>0x70F8</code> |
| <code>stealth</code> | <code>flashme_v8_lite_stealth.bin</code> | <code>flashme_v8_lite_stealth.crc16</code> | <code>0x20F7</code> |
| <code>normal</code> | <code>flashme_v8_lite.bin</code> | <code>flashme_v8_lite.crc16</code> | <code>0x33C8</code> |