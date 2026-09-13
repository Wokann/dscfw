# FlashMe TV-out image build sources

[简体中文](README.zh-cn.md)

## Declaration

This source tree builds DS Lite TV-out FlashMe image templates from user-supplied
Nintendo firmware input. It does not track or distribute Nintendo firmware
images or original FlashMe images. Only the V8a Lite package is currently
provided.

## Build

Place <code>official_v6.bin</code> in the <code>dscfw</code> repository root,
then run:

~~~sh
make
~~~

This builds every TV-out package. Run <code>make v8a-lite</code> for the single
top-level package, or enter <code>v8a/lite</code> and run <code>make</code>.
Use <code>make variants</code> there to build every recorded variant.

## Nintendo input CRC-32/ISO-HDLC

Before unpacking, the build virtually fills the private byte range
<code>[0x2A, 0x180)</code> with <code>FF</code>, then calculates CRC-32/ISO-HDLC
over <code>[0x000000, 0x3F9B8)</code>. The source input is not modified. The
expected value is <code>0x594067E9</code>.

<code>official_v6.crc32</code> in the <code>dscfw</code> repository root is a
fixed comparison record and is never rewritten by validation.

## TV-out output CRC-16/IBM

The archived <code>noauto</code> variant compares <code>[0x000000, 0x3F800)</code>
with its fixed UTF-8 <code>*.crc16</code> record. A mismatch is reported after
BIN creation without rewriting the record or failing the build. Other
unofficial variants only print the current CRC-16/IBM value.

| Package | Model | Nintendo input | Output variants | CRC range |
| --- | --- | --- | --- | --- |
| <code>v8a/lite</code> | Lite | <code>official_v6.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |

## Reference

A local copy of the DS Lite-specific display-register notes is kept in
[v8a/lite/include/ds_lite_nitro2_registers.h](v8a/lite/include/ds_lite_nitro2_registers.h).
Its header records [melonDS post #5772](https://melonds.kuribo64.net/board/thread.php?pid=5772),
its publisher Generic (RSDuck), and the post's stated Gericom source.
