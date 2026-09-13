# FlashMe V7 New Lite build package

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
| <code>stealth</code> | <code>flashme_v7_new_lite_stealth.bin</code> | <code>flashme_v7_new_lite_stealth.crc16</code> | <code>0xF5C9</code> |
| <code>normal</code> | <code>flashme_v7_new_lite.bin</code> | <code>flashme_v7_new_lite.crc16</code> | <code>0xF684</code> |

## Runtime mechanism

- Primary header H gives the boot ROM the firmware locations and RAM staging addresses for P1 (ARM9) and P2 (ARM7).
- P1 and P2 begin together. P2 reads early keys and the Slot-2 marker: it can take the recovery route or read FlashMe's FH.
- FH is FlashMe's secondary header stored in firmware. Its encoded addresses locate the second-stage FP1 (ARM9) and FP2 (ARM7) images.
- FP1 handles ARM9 warm/cold state and continuation. FP2 makes the retained-Nintendo versus FlashMe selection, completes ARM7-side synchronization, then transfers control.
- P3 is retained ARM9 GUI/verification code, P4 is ARM7 wireless code, and P5 is graphics/data. Only documented sites are patched.
## Analysis notes

- This is the maintained Lite copy. The independently installed V7 Lite beta was verified identical to the Lite firmware embedded in both Lite and Phat integrated installers; it may be beta 2, but that identity is not confirmed.
- A nonmatching card can reach the private <code>F2 → F1 → A4</code> DSLink/MK2/MK3 probe, then provide an NDS header for ARM9/ARM7 DMA loading.
- The command sequence is not generic Slot-1 traffic; unrelated-card compatibility remains unconfirmed.