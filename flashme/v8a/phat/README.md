# FlashMe V8a Phat build package

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
| <code>noauto</code> | <code>flashme_v8a_phat_noauto.bin</code> | <code>flashme_v8a_phat_noauto.crc16</code> | <code>0x0708</code> |
| <code>stealth_noauto</code> | <code>flashme_v8a_phat_stealth_noauto.bin</code> | <code>flashme_v8a_phat_stealth_noauto.crc16</code> | <code>0x842F</code> |
| <code>stealth</code> | <code>flashme_v8a_phat_stealth.bin</code> | <code>flashme_v8a_phat_stealth.crc16</code> | <code>0x0828</code> |
| <code>normal</code> | <code>flashme_v8a_phat.bin</code> | <code>flashme_v8a_phat.crc16</code> | <code>0xF482</code> |

## Runtime mechanism

- Primary header H gives the boot ROM the firmware locations and RAM staging addresses for P1 (ARM9) and P2 (ARM7).
- P1 and P2 begin together. P2 reads early keys and the Slot-2 marker: it can take the recovery route or read FlashMe's FH.
- FH is FlashMe's secondary header stored in firmware. Its encoded addresses locate the second-stage FP1 (ARM9) and FP2 (ARM7) images.
- FP1 handles ARM9 warm/cold state and continuation. FP2 makes the retained-Nintendo versus FlashMe selection, completes ARM7-side synchronization, then transfers control.
- P3 is retained ARM9 GUI/verification code, P4 is ARM7 wireless code, and P5 is graphics/data. Only documented sites are patched.
## Analysis notes

- Start+Select, or Slot-2 Game Code <code>BOOT</code>, enters a revised early route. ARM7 asks ARM9 to perform cold preparation through a mailbox.
- If <code>0x027FF80C + 0x0C</code> is zero, ARM7 issues standard <code>B7</code> reads using resident NDS-header ARM9/ARM7 source, destination, size, and entry fields; nonzero falls back to Slot-2.
- The state word's semantic meaning is unconfirmed. <code>noauto</code> changes the manual FlashMe selector to Select.
