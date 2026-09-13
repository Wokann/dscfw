# FlashMe V1 Phat build package

[简体中文](README.zh-cn.md)

## Declaration

This package contains ARMIPS source and CRC reference records only. It does
not distribute Nintendo firmware images or original FlashMe images.

## Build

Place <code>official_v3.bin</code> in the repository root, then run
<code>make</code> from this directory.

For the FH-relocated test build, run <code>make fix_fh</code>. It writes
<code>flashme_v1_phat_fix_fh.bin</code>, placing FH at the V5+ address
<code>0x3F680</code> and compiling P2 to read the same address. As this is an
intentional non-original layout, it produces only the BIN, prints its CRC-16,
and has no CRC record or original-image CRC comparison.

## CRC-16/IBM

The original-layout build verifies <code>[0x000000, 0x3FDFE)</code>. Its UTF-8
<code>*.crc16</code> record is a fixed archival reference and is never created
or updated by a build. A mismatch is reported after BIN creation and is not
fatal to the build.

| Variant | Output | CRC record | CRC-16 |
| --- | --- | --- | --- |
| <code>normal</code> | <code>flashme_v1_phat.bin</code> | <code>flashme_v1_phat.crc16</code> | <code>0x53FA</code> |

## Runtime mechanism

- Primary header H gives the boot ROM the firmware locations and RAM staging addresses for P1 (ARM9) and P2 (ARM7).
- P1 and P2 begin together. P2 reads early keys and the Slot-2 marker: it can take the recovery route or read FlashMe's FH.
- FH is FlashMe's secondary header stored in firmware. Its encoded addresses locate the second-stage FP1 (ARM9) and FP2 (ARM7) images.
- FP1 handles ARM9 warm/cold state and continuation. FP2 makes the retained-Nintendo versus FlashMe selection, completes ARM7-side synchronization, then transfers control.
- P3 is retained ARM9 GUI/verification code, P4 is ARM7 wireless code, and P5 is graphics/data. Only documented sites are patched.
## Analysis notes

- P2 treats low-active A+B+Start+Select and Slot-2 Game Code <code>BOOT</code> as an early recovery route. All other ordinary cases load FH and install FP1/FP2.
- P3 NOPs the Nintendo Logo gate and forces two verifier routines to return success. FP1 separately neutralizes two retained-component CRC decisions.
- FP2 selects FlashMe for <code>PASS</code>, <code>DSBooter</code>, or forced A+B+X+Y; Select retains Nintendo firmware. normal PWM-fades black to white, but hardware testing confirms V1 still shows the health prompt afterward.
