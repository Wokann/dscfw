# FlashMe V8a Lite build package

[简体中文](README.zh-cn.md)

## Declaration

This package contains ARMIPS source and CRC reference records only. It does
not distribute Nintendo firmware images or original FlashMe images.

## Build

Place <code>official_v6.bin</code> in the <code>dscfw</code> repository root, then run
<code>make</code> from this directory. TV-out is enabled by default for normal,
stealth, noauto, and stealth-noauto builds. Their FP2 streams use the TV-out
LZ-CUE P12 profile. Run <code>make variants</code> to build every variant.

The new TV-out FP2 compressed stream is shorter than the V8a Lite noauto
stream. The archived IPS patch was made by overwriting that stream in place on
the V8a base, leaving old FP2 bytes after the effective stream. To reproduce
the noauto image byte-for-byte, its build uses
<code>dsfwtool -b --no-stream-padding</code> to retain that base tail. Normal,
stealth, and stealth-noauto do not require byte restoration, so they are fresh
builds without <code>-b</code>.

## CRC-16/IBM

Only <code>noauto</code> has a fixed CRC-16/IBM check over
<code>[0x000000, 0x3F800)</code>: its normalized TV-out value is
<code>0x1634</code>. The UTF-8 record is an archival reference and is never
created or updated by a build. The other three variants output only BIN files
and print their current CRC-16/IBM value to the terminal. A noauto mismatch is
reported after BIN creation and is not fatal to the build.

| Variant | Output | CRC-16 behavior |
| --- | --- | --- |
| <code>noauto</code> | <code>flashme_v8a_lite_noauto_tvout.bin</code> | fixed <code>flashme_v8a_lite_noauto_tvout.crc16</code>: <code>0x1634</code> |
| <code>stealth_noauto</code> | <code>flashme_v8a_lite_stealth_noauto_tvout.bin</code> | terminal only |
| <code>stealth</code> | <code>flashme_v8a_lite_stealth_tvout.bin</code> | terminal only |
| <code>normal</code> | <code>flashme_v8a_lite_tvout.bin</code> | terminal only |

## Runtime mechanism

- Primary header H gives the boot ROM the firmware locations and RAM staging addresses for P1 (ARM9) and P2 (ARM7).
- P1 and P2 begin together. P2 reads early keys and the Slot-2 marker: it can take the recovery route or read FlashMe's FH.
- FH is FlashMe's secondary header stored in firmware. Its encoded addresses locate the second-stage FP1 (ARM9) and FP2 (ARM7) images.
- FP1 handles ARM9 warm/cold state and continuation. FP2 makes the retained-Nintendo versus FlashMe selection, completes ARM7-side synchronization, then transfers control.
- P3 is retained ARM9 GUI/verification code, P4 is ARM7 wireless code, and P5 is graphics/data. Only documented sites are patched.

## Analysis notes

- **TV-out modification mechanism.** TV-out-specific code exists only in FP2,
  which embeds the retained V6 ARM7 P2. During its original startup
  initialization, P2 writes <code>0xFFFF</code> to <code>0x04001080</code> at
  <code>RetailP2RamAddress + 0x58E</code>. This is the one-shot DS Lite hidden-
  feature lock, <code>REG_REGCNT</code>: once written, the following display-
  switching registers cannot be read or written. TVout replaces that store with
  a Thumb call and changes the loaded literal at <code>+0x76C</code> to
  <code>0x4000</code>. The helper consequently writes
  <code>0x04001090 = 1</code> (<code>REG_DISPCNT2</code>, single-screen mode)
  and <code>0x040010A0 = 0x4000</code> (<code>REG_DISPSW</code>, TV-out enable).
  Thus the essential change is not the IPS itself: it replaces Nintendo V6's
  lock operation with hidden TV-output enablement. Register names and bit
  meanings are corroborated by [melonDS's DS Lite register record](https://melonds.kuribo64.net/board/thread.php?pid=5772); this repository's V6 P2 control flow independently confirms the original lock store and its replacement site.
- <code>ndstvout-patch.ips</code> is only an archival byte reference from
  [LNH-team / Lost-NDS-TV](https://github.com/LNH-team/Lost-NDS-TV/). It is not
  a build input and is not used to infer the runtime mechanism above.
- Start+Select, or Slot-2 Game Code <code>BOOT</code>, enters a revised early route. ARM7 asks ARM9 to perform cold preparation through a mailbox.
- If <code>0x027FF80C + 0x0C</code> is zero, ARM7 issues standard <code>B7</code> reads using resident NDS-header ARM9/ARM7 source, destination, size, and entry fields; nonzero falls back to Slot-2.
- The state word's semantic meaning is unconfirmed. <code>noauto</code> changes the manual FlashMe selector to Select.
