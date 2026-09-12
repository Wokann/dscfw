# FlashMe V8a Lite build package

[简体中文](README.zh-cn.md)

## Declaration

This package contains ARMIPS source and CRC reference records only. It does
not distribute Nintendo firmware images or original FlashMe images.

## Build

Place <code>official_v6.bin</code> in the <code>flashme/</code> root, then run
<code>make</code> from this directory.
To build every listed variant, run <code>make variants</code>.

## CRC-16/IBM

Each build verifies the byte range <code>[0x000000, 0x3F800)</code>.
The UTF-8 <code>*.crc16</code> records contain the reference values.

| Variant | Output | CRC record | CRC-16 |
| --- | --- | --- | --- |
| <code>noauto</code> | <code>flashme_v8a_lite_noauto.bin</code> | <code>flashme_v8a_lite_noauto.crc16</code> | <code>0x744D</code> |
| <code>stealth_noauto</code> | <code>flashme_v8a_lite_stealth_noauto.bin</code> | <code>flashme_v8a_lite_stealth_noauto.crc16</code> | <code>0xAB10</code> |
| <code>stealth</code> | <code>flashme_v8a_lite_stealth.bin</code> | <code>flashme_v8a_lite_stealth.crc16</code> | <code>0x6652</code> |
| <code>normal</code> | <code>flashme_v8a_lite.bin</code> | <code>flashme_v8a_lite.crc16</code> | <code>0xFE96</code> |