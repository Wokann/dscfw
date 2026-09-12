# FlashMe V3 Phat build package

[简体中文](README.zh-cn.md)

## Declaration

This package contains ARMIPS source and CRC reference records only. It does
not distribute Nintendo firmware images or original FlashMe images.

## Build

Place <code>official_v3.bin</code> in the <code>flashme/</code> root, then run
<code>make</code> from this directory.

## CRC-16/IBM

Each build verifies the byte range <code>[0x000000, 0x3FDFE)</code>.
The UTF-8 <code>*.crc16</code> records contain the reference values.

| Variant | Output | CRC record | CRC-16 |
| --- | --- | --- | --- |
| <code>normal</code> | <code>flashme_v3_phat.bin</code> | <code>flashme_v3_phat.crc16</code> | <code>0xB439</code> |