# FlashMe V4 Phat build package

[简体中文](README.zh-cn.md)

## Declaration

This package contains ARMIPS source and CRC reference records only. It does
not distribute Nintendo firmware images or original FlashMe images.

## Build

Place <code>official_v3.bin</code> in the <code>flashme/</code> root, then run
<code>make</code> from this directory.
To build every listed variant, run <code>make variants</code>.

For the FH-relocated test build, run <code>make fix_fh</code>. It writes
<code>flashme_v4_phat_fix_fh.bin</code>, placing FH at the V5+ address
<code>0x3F680</code> and compiling P2 to read the same address. For the
health-prompt-retaining <code>stealth</code> build, run
<code>make VARIANT=stealth fix_fh</code>; its output is
<code>flashme_v4_phat_stealth_fix_fh.bin</code>. These intentional
non-original layouts record their CRC instead of comparing against the
original-image CRC references.

## CRC-16/IBM

Each build verifies the byte range <code>[0x000000, 0x3FDFE)</code>.
The UTF-8 <code>*.crc16</code> records contain the reference values.

| Variant | Output | CRC record | CRC-16 |
| --- | --- | --- | --- |
| <code>stealth</code> | <code>flashme_v4_phat_stealth.bin</code> | <code>flashme_v4_phat_stealth.crc16</code> | <code>0xB864</code> |
| <code>normal</code> | <code>flashme_v4_phat.bin</code> | <code>flashme_v4_phat.crc16</code> | <code>0xE316</code> |
