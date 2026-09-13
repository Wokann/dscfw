# FlashMe V5 Phat build package

[简体中文](README.zh-cn.md)

## Declaration

This package contains ARMIPS source and CRC reference records only. It does
not distribute Nintendo firmware images or original FlashMe images.

## Build

Place <code>official_v3.bin</code> in the <code>flashme/</code> root, then run
<code>make</code> from this directory.
To build every listed variant, run <code>make variants</code>.

## CRC-16/IBM

Each build verifies the byte range <code>[0x000000, 0x3F800)</code>.
The UTF-8 <code>*.crc16</code> records contain the reference values.

| Variant | Output | CRC record | CRC-16 |
| --- | --- | --- | --- |
| <code>stealth</code> | <code>flashme_v5_phat_stealth.bin</code> | <code>flashme_v5_phat_stealth.crc16</code> | <code>0x0927</code> |
| <code>normal</code> | <code>flashme_v5_phat.bin</code> | <code>flashme_v5_phat.crc16</code> | <code>0x9BD7</code> |

## Runtime mechanism

- Primary header H gives the boot ROM the firmware locations and RAM staging addresses for P1 (ARM9) and P2 (ARM7).
- P1 and P2 begin together. P2 reads early keys and the Slot-2 marker: it can take the recovery route or read FlashMe's FH.
- FH is FlashMe's secondary header stored in firmware. Its encoded addresses locate the second-stage FP1 (ARM9) and FP2 (ARM7) images.
- FP1 handles ARM9 warm/cold state and continuation. FP2 makes the retained-Nintendo versus FlashMe selection, completes ARM7-side synchronization, then transfers control.
- P3 is retained ARM9 GUI/verification code, P4 is ARM7 wireless code, and P5 is graphics/data. Only documented sites are patched.
## Analysis notes

- FH moves from <code>0x3FC80</code> to <code>0x3F680</code>; P2 and packaging use that same location, avoiding the Wi-Fi access-point settings area.
- The installer identity/layout changes too, so a V1–V4 update by the older path needs SL1 bridging.
- normal/stealth user-visible policy remains the V4 policy.