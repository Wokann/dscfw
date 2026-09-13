# FlashMe V8 Phat build package

[简体中文](README.zh-cn.md)

## Declaration

This package contains ARMIPS source and CRC reference records only. It does
not distribute Nintendo firmware images or original FlashMe images.

## Build

Place <code>official_v3.bin</code> in the repository root, then run
<code>make</code> from this directory.
To build every listed variant, run <code>make variants</code>.

## CRC-16/IBM

Each build compares <code>[0x000000, 0x3F800)</code> with the value read from
its UTF-8 <code>*.crc16</code> record. Records are fixed and never rewritten;
a mismatch is reported after BIN creation without failing the build.

| Variant | Output | CRC record | CRC-16 |
| --- | --- | --- | --- |
| <code>noauto</code> | <code>flashme_v8_phat_noauto.bin</code> | <code>flashme_v8_phat_noauto.crc16</code> | <code>0xE2A5</code> |
| <code>stealth_noauto</code> | <code>flashme_v8_phat_stealth_noauto.bin</code> | <code>flashme_v8_phat_stealth_noauto.crc16</code> | <code>0x9909</code> |
| <code>stealth</code> | <code>flashme_v8_phat_stealth.bin</code> | <code>flashme_v8_phat_stealth.crc16</code> | <code>0x58DF</code> |
| <code>normal</code> | <code>flashme_v8_phat.bin</code> | <code>flashme_v8_phat.crc16</code> | <code>0x5753</code> |

## Runtime mechanism

- Primary header H gives the boot ROM the firmware locations and RAM staging addresses for P1 (ARM9) and P2 (ARM7).
- P1 and P2 begin together. P2 reads early keys and the Slot-2 marker: it can take the recovery route or read FlashMe's FH.
- FH is FlashMe's secondary header stored in firmware. Its encoded addresses locate the second-stage FP1 (ARM9) and FP2 (ARM7) images.
- FP1 handles ARM9 warm/cold state and continuation. FP2 makes the retained-Nintendo versus FlashMe selection, completes ARM7-side synchronization, then transfers control.
- P3 is retained ARM9 GUI/verification code, P4 is ARM7 wireless code, and P5 is graphics/data. Only documented sites are patched.
## Analysis notes

- V8 removes the selector call into V7's automatic private DSLink/MK2/MK3 probe. The <code>fp2_aux_*</code> helpers remain but are not reached by the selector.
- Therefore normal/stealth no longer automatically send the private Slot-1 sequence; <code>noauto</code>/<code>stealth_noauto</code> require manual A+B+X+Y selection.
- Phat retains its existing normal fade policy.
