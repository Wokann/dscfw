# FlashMe image build sources

[简体中文](README.zh-cn.md)

## Declaration

This source tree builds FlashMe image templates from user-supplied Nintendo
firmware inputs. It does not track or distribute Nintendo firmware images or
original FlashMe images. FlashMe V2 is unavailable because no authenticated
image or reliable technical source is present.

## Build

Place <code>official_v3.bin</code> and <code>official_v6.bin</code> in the
repository root. Build every available package with:

~~~sh
make
~~~

Run a single top-level target such as <code>make v1</code> or
<code>make v8a-lite</code> to build one package. Each package directory also
accepts <code>make</code>; packages with multiple recorded outputs accept
<code>make variants</code>.

## Nintendo input CRC-32/ISO-HDLC

Before unpacking, the build virtually fills the private byte range
<code>[0x2A, 0x180)</code> with <code>FF</code>, then calculates CRC-32/ISO-HDLC
over the stated half-open range. The source input is not modified.

| Input | CRC range | Expected CRC-32 |
| --- | --- | --- |
| <code>official_v3.bin</code> | <code>[0x000000, 0x3F6F8)</code> | <code>0x96DF1D27</code> |
| <code>official_v6.bin</code> | <code>[0x000000, 0x3F9B8)</code> | <code>0x594067E9</code> |

The root-level <code>official_v3.crc32</code> and <code>official_v6.crc32</code>
files are fixed comparison records and are never rewritten by validation.

## FlashMe output CRC-16/IBM

Each historical package Makefile compares its listed half-open range with the
value read from its fixed UTF-8 <code>*.crc16</code> record. It reports a
mismatch after BIN creation without rewriting the record or failing the build.

| Package | Model | Nintendo input | Output variants | CRC range |
| --- | --- | --- | --- | --- |
| <code>v1</code> | Phat | <code>official_v3.bin</code> | <code>normal</code> | <code>0x3FDFE</code> |
| <code>v3</code> | Phat | <code>official_v3.bin</code> | <code>normal</code> | <code>0x3FDFE</code> |
| <code>v4</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3FDFE</code> |
| <code>v5</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v6</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v7_old/phat</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v7_old/lite</code> | Lite | <code>official_v6.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v7_new/phat</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v7_new/lite</code> | Lite | <code>official_v6.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v8/phat</code> | Phat | <code>official_v3.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |
| <code>v8/lite</code> | Lite | <code>official_v6.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |
| <code>v8a/phat</code> | Phat | <code>official_v3.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |
| <code>v8a/lite</code> | Lite | <code>official_v6.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |
