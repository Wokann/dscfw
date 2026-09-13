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

## Runtime mechanism

- Primary header H gives the boot ROM the firmware locations and RAM staging addresses for P1 (ARM9) and P2 (ARM7).
- P1 and P2 begin together. P2 reads early keys and the Slot-2 marker: it can take the recovery route or read FlashMe's FH.
- FH is FlashMe's secondary header stored in firmware. Its encoded addresses locate the second-stage FP1 (ARM9) and FP2 (ARM7) images.
- FP1 handles ARM9 warm/cold state and continuation. FP2 makes the retained-Nintendo versus FlashMe selection, completes ARM7-side synchronization, then transfers control.
- P3 is retained ARM9 GUI/verification code, P4 is ARM7 wireless code, and P5 is graphics/data. Only documented sites are patched.
## Analysis notes

- normal keeps V3's four health-prompt edits and its PWM fade.
- stealth omits exactly those four retained-P1 edits and bypasses the fade, giving the stock-like white startup followed by the health prompt.
- Both variants retain the P3 verification edits and the retained-component CRC bypasses.