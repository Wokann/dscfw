# FlashMe V8 Lite build package

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
| <code>noauto</code> | <code>flashme_v8_lite_noauto.bin</code> | <code>flashme_v8_lite_noauto.crc16</code> | <code>0xAF7B</code> |
| <code>stealth_noauto</code> | <code>flashme_v8_lite_stealth_noauto.bin</code> | <code>flashme_v8_lite_stealth_noauto.crc16</code> | <code>0x70F8</code> |
| <code>stealth</code> | <code>flashme_v8_lite_stealth.bin</code> | <code>flashme_v8_lite_stealth.crc16</code> | <code>0x20F7</code> |
| <code>normal</code> | <code>flashme_v8_lite.bin</code> | <code>flashme_v8_lite.crc16</code> | <code>0x33C8</code> |