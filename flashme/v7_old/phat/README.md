# FlashMe V7 Old Phat build package

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
| <code>stealth</code> | <code>flashme_v7_old_phat_stealth.bin</code> | <code>flashme_v7_old_phat_stealth.crc16</code> | <code>0xFB92</code> |
| <code>normal</code> | <code>flashme_v7_old_phat.bin</code> | <code>flashme_v7_old_phat.crc16</code> | <code>0xE175</code> |

## Runtime mechanism

- Primary header H gives the boot ROM the firmware locations and RAM staging addresses for P1 (ARM9) and P2 (ARM7).
- P1 and P2 begin together. P2 reads early keys and the Slot-2 marker: it can take the recovery route or read FlashMe's FH.
- FH is FlashMe's secondary header stored in firmware. Its encoded addresses locate the second-stage FP1 (ARM9) and FP2 (ARM7) images.
- FP1 handles ARM9 warm/cold state and continuation. FP2 makes the retained-Nintendo versus FlashMe selection, completes ARM7-side synchronization, then transfers control.
- P3 is retained ARM9 GUI/verification code, P4 is ARM7 wireless code, and P5 is graphics/data. Only documented sites are patched.
## Analysis notes

- After the ordinary selector fails to match <code>PASS</code>/<code>DSBooter</code>, V7 Old Phat probes Slot-1 with private <code>F2 → F1 → A4</code> traffic.
- A matching DSLink/MK2/MK3-style response supplies an NDS header; ARM9/ARM7 sections are DMA-loaded and entered.
- The traffic is not a generic Slot-1 protocol. Risk to unrelated Slot-1 cards is inferred from repeated private signaling; the exact hardware result is unconfirmed.
