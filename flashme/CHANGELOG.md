# FlashMe source maintenance record

[简体中文](CHANGELOG.zh-cn.md)

## Declaration

This file intentionally contains no historical feature analysis or inferred
version-change claims. The source tree does not distribute Nintendo firmware
or original FlashMe images. FlashMe V2 has no build package or CRC baseline.

## Build and CRC records

Use <code>make</code> in the <code>flashme/</code> root after supplying
<code>official_v3.bin</code> and <code>official_v6.bin</code>. Input verification
uses CRC-32/ISO-HDLC with <code>[0x2A, 0x180)</code> virtually filled with
<code>FF</code>; output verification uses CRC-16/IBM over each package's
declared range. See [README.md](README.md) for the current build and checksum
tables.