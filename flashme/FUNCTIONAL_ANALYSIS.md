# FlashMe V1–V8a functional analysis

[中文](FUNCTIONAL_ANALYSIS.zh-cn.md)

## Scope, evidence, and terminology

This is a fresh, code-led analysis of the reconstructed FlashMe release
templates in this directory.  It deliberately does **not** reuse earlier
release-note interpretations or speculative annotations.  The evidence base
is limited to the extracted/reconstructed assembly for V1, V3, V4, V5, V6,
V7 Old, V7 New, V8, and V8a, plus the address-oriented Nintendo
`official_v3` and `official_v6` listings under [`../official/`](../official/).
The local `dsfwtool` documentation is used only to cross-check stored
component layers and header ownership; the supplied BIOS7/BIOS9 listings are
used to identify concrete SVC and private-BIOS call behavior.  The local
FlashMe installer ARM7 source is used only for its explicit `H+0x17C` /
`FH+0x17C` version-recognition logic, and the local HBFirmware builder only
where its source comments and assignments directly identify the `H+0x17C` and
`H+0x17E` conventions.  Neither source is treated as evidence for unshown
FlashMe release behavior.

V2 is intentionally excluded.  There is no original V2 image or source-level
reference in this repository from which its behavior can be established.

Evidence labels have the following meaning:

- **[D] Direct** — an instruction sequence, constant, literal string, or
  control-flow edge in the reconstructed code establishes the statement.
- **[T] Traced** — the statement follows an immediate caller/callee path in
  the Nintendo V3/V6 listing or a FlashMe prefix.
- **[I] Interpretation** — a deliberately narrow functional reading of the
  direct behavior.  It never asserts an author intention or UI effect that
  has not been recovered from code.
- **[U] Unresolved** — the bytes and local effect are known, but their higher
  level purpose is not established.
- **[H] Historical research** — project-curated contemporary testing or release
  context; it records a historical trigger separately from direct code evidence.
- **[E] Hardware test** — a visible behavior observed by this project on real
  hardware; it establishes a version-level result without replacing
  instruction-level control-flow attribution.

“Nintendo V3” and “Nintendo V6” below always mean the two Nintendo firmware
bases used by this project; they do not mean FlashMe V3 or FlashMe V6.
FlashMe Phat templates retain Nintendo V3 P1/P2/P3 material, while the Lite
templates introduced with V7 retain Nintendo V6 material.  P4 and P5 are
unchanged `incbin` payloads in every analysed FlashMe build.

## Component model visible in every reconstructed build

Each image has two layers of boot components:

| Component | Directly visible construction | Functional reading |
| --- | --- | --- |
| `H` | A header derived from the source header, with FlashMe P1/P2 metadata and private/calibration fields handled separately. | **[D]** Primary boot metadata for the new P1/P2 pair. |
| `P1`, `P2` | New, compact ARM9 and ARM7 primary programs. | **[D]** They run before the retained Nintendo payloads and select/prepare handoff paths. |
| `FH` | A second header with FP1/FP2 metadata. | **[D]** Metadata used to load the retained-payload layer. |
| `FP1`, `FP2` | A FlashMe-written prefix followed by the whole original Nintendo P1/P2 image. | **[D]** The prefix runs first, then branches into the retained Nintendo component. |
| retained P3 | Nintendo V3 on Phat, Nintendo V6 on Lite from V7 onward, with three small patch sites. | **[D]** It preserves the original component except for the listed verification/state changes. |
| P4, P5 | Direct `incbin` of the source component. | **[D]** No FlashMe code patch is emitted for either component. |

The FP1/FP2 prefixes are placed immediately before the retained component in
RAM (`FlashMeFp{1,2}RamAddress = RetailP{1,2}RamAddress - prefixBytes`).
The retained component is then emitted at its original runtime address.  This
explains why a branch from a prefix can enter an original P1/P2 routine without
relocating its internal absolute references.

The prefix is `0x200` bytes through V6 and `0x400` bytes from V7 onward.
That is a directly visible layout change; its broader design motivation is not
assumed here.

### P3 runtime-coordinate correction

The reconstructed P3 patch sources now use the P3 execution bases recovered
from Nintendo P1: `0x02358D00` for the Nintendo V3-derived Phat line and
`0x02358E00` for the Nintendo V6-derived Lite line. **[D/T]** In each P1,
the P3/P4 decode-and-CRC path supplies exactly that first address as the P3
output range, and the decoded P3 entry's first cross-component `BL` resolves
into P1 only at that base. The earlier convenience coordinate `0x02380000`
is therefore not treated as a P3 RAM address. Because `headersize` and every
following P3 `org` share the same base symbol, this coordinate correction
preserves the generated component's raw byte offsets.

Stored format and runtime location are deliberately kept separate.  The local
[dsfwtool component reference](../../dsfwtool/README.md) records the primary
P1/P2 on-image layers as encrypted P12/LZ10 streams, while P3/P4/P5 use P345
two-stream static-Huffman data.  Consequently, a P345 decoder *located in
runtime P1* below is a decoder for other firmware payloads; it is not evidence
that the stored P1 image itself uses Huffman coding.

### Runtime proof of the two P12 layers

The distinction between encrypted primary P1/P2 and unencrypted FP1/FP2 is
also visible in the supplied BIOS7 execution code, independently of the tool
documentation:

- BIOS7 boot paths call `FUN_00002462`. It initialises the KEY1 state, reads
  P1/P2 descriptors from the loaded primary header, and enters
  `SVC_LZ77UnCompVRAM` using descriptor `UNK_000033E0`. That descriptor's
  byte reader is `FUN_00002330`: each eight-byte refill transfers serial data
  and calls `Decrypt_64bit` before exposing compressed bytes to LZ77.
- Every recovered FlashMe primary P2 instead supplies its own three-word
  descriptor for the secondary FH's FP1/FP2 streams. Its `p2_legacy_wait`
  reads a byte directly from `REG_SPIDATA`, writes it back to clock the next
  byte, and returns it to `SVC_LZ77UnCompVRAM`; the FlashMe callback path
  contains no `Decrypt_64bit` invocation.

**[D/T]** Thus the execution paths themselves support dsfwtool's layer model:
the Nintendo BIOS consumes encrypted primary P12 data, while FlashMe's primary
P2 consumes the unencrypted secondary FP1/FP2 P12 data. The common LZ10
decoder ABI explains why both layers can share the same decompression routine
without sharing the encryption step.

### Verified boot-loader boundary

This is a component-loader relationship, rather than a claim that every ARM9
and ARM7 instruction below executes serially:

```text
BIOS7 boot controller (FUN_0000124A)
  └─ FUN_00002462: KEY1 + encrypted P12 byte reader + LZ10
       ├─ primary P1 at its H-derived ARM9 destination
       └─ primary P2 at its H-derived ARM7 destination

FlashMe primary P2
  └─ secondary FH read + direct SPI byte reader + the same LZ10 ABI
       ├─ FP1 = FlashMe prefix + retained Nintendo P1
       └─ FP2 = FlashMe prefix + retained Nintendo P2

Retained Nintendo P2
  └─ stages H-described P3/P4 streams together and P5 separately in RAM
       └─ retained Nintendo P1 P345 decoder reconstructs P3, P4, then P5
          and applies the corresponding P3/P4-combined and P5 CRC16 gates
```

**[D/T]** The BIOS7 controller has three visible branches that call
`FUN_00002462`; the loader uses the primary-header descriptors.  The FlashMe
P2 source instead reads FH descriptor fields and reaches FP1/FP2 through its
own callback table.  This separates two questions that otherwise look alike:
the BIOS decides how a primary P12 stream is decrypted and decompressed, while
FlashMe decides how the already-plain FP layer is read and decompressed.  The
P345 decoder invoked later from retained P1 is a separate P3/P4/P5 payload-loader
stage. The retained P2 staging code identifies the first two as the
`part3`/`part4` pair with a shared CRC16, and P5 as its separate field. The
on-image layout and header ownership are cross-checked against the
local [dsfwtool component reference](../../dsfwtool/README.md) and
[`firmware_header` field definition](../../dsfwtool/include/firmware.h), while
the execution edges are in the supplied [BIOS7 listing](../../ndsbios/bios7.s).

## Hardware and ABI anchors

The names used below are anchored in both GBATEK and libnds rather than guessed
from the FlashMe labels.  These are nomenclature sources, not evidence of
FlashMe author intent.

| Item used by FlashMe | Code-visible behavior | Verified definition |
| --- | --- | --- |
| `REG_KEYINPUT` / `REG_KEYXY` | All key tests branch when a tested bit is clear. | libnds exposes the button masks and reads the register inverted in its key scanner, which confirms the active-low convention. [input.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/input.h), [keys.c](https://raw.githubusercontent.com/devkitPro/libnds/master/source/arm9/keys.c) |
| `REG_IPC_SYNC` | FP1/FP2 exchange small phase values through its high-byte write / low-nibble observation pattern. | [GBATEK — NDS IPC](https://doc.kodewerx.org/documents/gbatek.html), [libnds ipc.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/ipc.h) |
| `REG_BLDALPHA_SUB` (`0x04001052`) | Nintendo P1 transition A writes packed 5-bit alpha coefficients here. | [libnds arm9/video.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/arm9/video.h) |
| `REG_MASTER_BRIGHT` / `_SUB` | The Nintendo P3 state gate passes these two addresses to its P1 writer. | [libnds arm9/video.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/arm9/video.h) |
| ARM9 `REG_POWERCNT = 0x820F` | FP1 warm paths and preparation code write this halfword before their later handoff/phase work. | `0x820F` sets POWCNT1 bits for the LCD, 2D engine A, 3D renderer, 3D geometry engine, 2D engine B, and LCD swap. It is a concrete display-power/control value, not a cryptographic or header-state value. [GBATEK — NDS power control](https://doc.kodewerx.org/documents/gbatek.html), [libnds system.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/system.h) |
| `REG_SPICNT` / `REG_SPIDATA` | FP2 and later P2 programs issue `0x8A00, 0x84`, then `0x8200, 0x00`. | In `SPICNT`, device-select value `2` is the touchscreen controller; control byte `0x84` starts a 12-bit, single-ended channel-0 conversion. [GBATEK — NDS SPI and touchscreen controller](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md) |
| auxiliary/card registers | V7 FP2 and V8a P2 poll card control, read a header, and use NDS header ARM9/ARM7 load fields. | [libnds card.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/card.h), [memory.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/memory.h), [GBATEK — NDS cartridges](https://doc.kodewerx.org/documents/gbatek.html) |
| loaded NDS-header logo | Nintendo P3 compares `0x027FFEC0` to `0xFFFF0020` before one patched state transition. | GBATEK places the 156-byte NDS Nintendo-logo field at header `+0xC0`; the header is loaded to `0x027FFE00`.  The supplied BIOS9 listing contains the reference logo at `0xFFFF0020`. [GBATEK — DS Cartridge Header](https://doc.kodewerx.org/documents/gbatek.html), [BIOS9 listing](../../ndsbios/bios9.s) |
| `0x027FFE24`, `+0x28`, `+0x34` | FlashMe's handoff code reads or writes these words through both the canonical address and the retail mirror. | They are standard loaded-NDS-header fields: ARM9 entry address, ARM9 RAM address, and ARM7 entry address.  `0x023FFE24/+0x28` are the retail 4 MiB RAM mirrors of the first two fields, not FlashMe-private storage. [GBATEK — NDS BIOS RAM and card header](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md) |
| `0x027FFF70` | V6-and-later FP1 writes a small ARM return trampoline here. | This is exactly the first address after the documented `0x170`-byte loaded card-header range. GBATEK describes this following range as unused and zero-filled at card boot; it assigns no trampoline ABI.  The address boundary is standard, but using it as a trampoline is FlashMe-local. [GBATEK — NDS BIOS RAM](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md) |
| `0x02100024` | V7-and-later FP1 dereferences this word on its fallback return path. | It is ordinary main RAM, with no dedicated GBATEK or libnds field definition. A Ghidra exact-constant scan of all decompressed Nintendo V3/V6 P1–P5 components finds no static literal reference; that cannot exclude a computed or external writer, but the visible FP1 read cannot prove a system-defined purpose. |
| ARM9 `SVC #0x0C` | V6-and-later FP1 invokes it with `r0 = 0xFFFF0020`, `r1 = 0x027FFEC0`, and `r2 = 0x28`. | The supplied [BIOS9 listing](../../ndsbios/bios9.s) maps it to `SVC_CpuFastSet`; `0x28` 32-bit words are copied, i.e. `0xA0` bytes. |
| `SVC #0x0E` | The Nintendo P1 wrapper is exactly `svc #0x0e; bx lr`. | [libnds bios.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/bios.h), [GBATEK — GetCRC16](https://doc.kodewerx.org/documents/gbatek.html) |
| ARM9 `SVC #0x1F` | FlashMe primary/FP1 code invokes it with `r0 = 1`. | In the supplied [BIOS9 listing](../../ndsbios/bios9.s), SVC table entry `0x1F` is `SVC_CustomPost`; it writes `r0` to `0x04000300` (`REG_POSTFLG`). |
| ARM7 `SVC #0x03` | FP2's normal timing helper and V8 Lite's `r0 = 0x280000` delay use it. | In the supplied [BIOS7 listing](../../ndsbios/bios7.s), it is `SVC_WaitByLoop`, a decrement-and-branch loop on `r0`. |
| ARM7 `SVC #0x08` | Every FP2 entry enables power, leaves a nonzero `r0`, sets `r1 = 0x3000`, and invokes it. | In the supplied BIOS7 listing it is `SVC_SoundBias`: a nonzero `r0` increments `REG_SOUNDBIAS` toward `0x200`, waiting `r1` iterations between steps. |
| BIOS7 ARM `0x000030E4` | Primary P2 enters this address through its `PrimaryP2ComputeRoutine` slot after staging either a secondary-layer or alternate route. | It is the ARM entry of BIOS7 `SVC_CpuFastSet` (the Thumb veneer is `0x000030E0`); its direct implementation copies or fills in eight-word groups according to the control word. [BIOS7 listing](../../ndsbios/bios7.s) |
| private BIOS7 `0x0000119D` | Several FP2 and V8a-P2 paths call the address retained under the historical source name `BiosBootReturnRoutine`. | It is the Thumb entry of `SignalBootFinish` in the supplied BIOS7 listing and byte-writes `1` to `REG_POSTFLG`. |
| private BIOS7 `0x00002369` | The historical source name is `BiosIpcSendRoutine`; FlashMe supplies `r0/r1/r2` and branches to it. | It is a generic SPI-byte helper, not IPC. In the ordinary retained-firmware and primary-P2 calls, `r0 = 0`, `r2 = 1` then `0` selects the Power Management device and holds then releases chip select; `r1 = 0` selects control register 0, and `r1 = 1` / `0x0D` writes its values. Thus `0x01` enables the sound amplifier and `0x0D` enables it plus both backlights. [GBATEK — SPI and power management](https://doc.kodewerx.org/documents/gbatek.html) |
| private BIOS7 `0x00002437` | The historical source name is `BiosCopyRoutine`; FlashMe gives it an address, RAM destination, and byte count. | It is a firmware-serial-flash read helper, not a CPU copy loop: it emits command `0x03` (`READ`), serializes the address, reads the requested bytes to RAM, then releases chip select. FlashMe's settings path supplies `0x3FE00`, `0x023FFC80`, and `0x180`, matching the two firmware user-settings areas and current-settings RAM. [GBATEK — firmware flash and settings map](https://doc.kodewerx.org/documents/gbatek.html) |
| private BIOS7 `0x00002A2B` | V8a primary P2 branches here with `p2_legacy_pool` in `r3`. | It is the Thumb entry of `SVC_LZ77UnCompVRAM`.  Its source code calls descriptor word `+0` to initialise the source, word `+8` for every compressed byte, and word `+4` on completion. |
| private BIOS7 `0x00002389`, `0x000033A5`, and `0x000022C7` | These are V8a's three `p2_legacy_pool` support addresses. | `0x2389` sends serial-flash `0x03` followed by a four-byte address; `0x33A5` performs a counted full-duplex main-SPI transfer through its caller buffer; and `0x22C7` issues the terminal zero-byte transfer and returns zero.  The descriptions are taken from the supplied BIOS7 instructions, rather than their old FlashMe source labels. |

## Nintendo ranges changed by FlashMe

The source labels and all address evidence are maintained in
[`../official/SEMANTIC_MAP.md`](../official/SEMANTIC_MAP.md).  The following
is the functional summary used by this analysis.

### Retained P1: P3/P4 and P5 CRC16 gates

| Nintendo base | Original range | FlashMe alteration | Established result |
| --- | --- | --- | --- |
| V3 | P1 `+0x6DE6` in `NintendoOfficialV3P1_P3P4Crc16Gate` | Replaces the P3/P4-combined CRC16 mismatch `bne` with Thumb NOP. | **[D]** The final comparison no longer selects the alternate `0x408` downstream argument; it follows the `0x400` path. |
| V3 | P1 `+0x6E3C` in `NintendoOfficialV3P1_P5Crc16Gate` | Replaces the independent P5 CRC16 mismatch `bne` with Thumb NOP. | **[D]** The success call is no longer conditional on that final CRC16 comparison. |
| V6 | P1 `+0x6DAE`, `+0x6E04` | V6-equivalent P3/P4 and P5 CRC16-gate Thumb NOPs. | **[D]** Same two CRC16-gate bypasses. |

The P2 staging path identifies the paired streams as P3/P4 and the separate
stream as P5: it reads `part3_romaddr`, `part4_romaddr`, `part34_crc16`, then
separately `part5_romaddr` and `part5_crc16`; this agrees with
[`FW_HEADER`](../../dsfwtool/include/firmware.h). The preceding decoder and
`SVC #0x0E` calls remain present. Therefore the direct conclusion is limited
to bypassing these post-decode P3/P4 and P5 CRC16 branch gates; this patch
alone is not evidence for RSA or signature verification bypass.

### Retained P3: state, cryptographic verification, and digest gates

| Nintendo base | Original range | FlashMe alteration | Established result |
| --- | --- | --- | --- |
| V3 | P3 `+0x1019C` in `NintendoOfficialV3P3_NdsHeaderLogoState0cTo0dGate` | `beq` becomes a Thumb NOP. | **[D/T]** The parent P3 dispatcher calls this handler for state `0x0C`.  Its P1 helper compares the loaded 156-byte NDS-header Nintendo-logo field (`0x027FFE00 + 0xC0`) with the ARM9-BIOS reference logo at `0xFFFF0020`.  A mismatch can no longer skip that state handler's `0x0D` write.  Earlier context checks and the two-master-brightness ramp remain. |
| V6 | P3 `+0x10198` | V6-equivalent Thumb NOP. | **[D/T]** The V6 parent dispatcher likewise calls its equivalent handler for state `0x0C`; the same NDS-header-logo gate is removed. |
| V3 | P3 `+0x13ED0` | Entire public-key formatted-digest entry becomes `mov r0,#1; bx lr`. | **[D/T]** The original converts two `0x80`-byte values plus a three-byte exponent-sized value to bignums, performs the public-key operation, then requires a recovered `0x01 || 0xFF... || 0x00 || DER DigestInfo`-shaped block and extracts a 20-byte OCTET STRING. That structure is the one specified for RSASSA-PKCS1-v1_5. [RFC 8017, §§8.2 and 9.2](https://www.rfc-editor.org/rfc/rfc8017.html#section-8.2) Every caller now receives success without that body. |
| V6 | P3 `+0x13EEC` | Same two-instruction stub. | **[D/T]** Same bignum, PKCS#1-shaped recovered-message, DER DigestInfo, and 20-byte extraction path is skipped. |
| V3 | P3 `+0x173C0` | Entire digest-comparison entry becomes `mov r0,#1; bx lr`. | **[D]** The caller that cleared a state flag on a zero return now retains the success condition. |
| V6 | P3 `+0x173DC` | Same two-instruction stub. | **[D]** Same outcome. |

The surrounding V3 and V6 P3 sequence is now directly recoverable.  The
parent dispatcher first uses a state-`0x0B` handler that counts through `0x1E`,
applies one interpolated value to both master-brightness writers, then resets
its counter and selects state `0x0C`.  The state-`0x0C` helper counts through
`0x5A`: for counts `1..0x0F` it writes `0x10 - interpolation` to both writers,
for `0x10..0x4B` it writes zero, and for `0x4C..0x5A` it writes the
interpolation.  Only after that timing helper succeeds do the context check
and Nintendo-logo comparison run; success selects state `0x0D`, whose handler
does subsequent cleanup and continuation work.  The FlashMe NOP changes only
the final conditional branch after the comparison.  It does not remove the
state-`0x0B` or state-`0x0C` brightness phases.  This establishes the local
state-machine behavior, but does not by itself identify the user-visible scene
of that state sequence.

The names used in the listings are still analyst-owned, but the first site's
behavior is directly recoverable rather than inferred only from data sizes: its
recovered-message parser follows the
`0x01 || 0xFF... || 0x00 || DER DigestInfo` form specified for
RSASSA-PKCS1-v1_5. The later V3/V6 site separately builds a SHA-1-style
20-byte digest (including the standard SHA-1 initial words) and calls a
concrete 20-byte equality routine. Unlike the P1 CRC modifications, the two
complete success stubs are direct evidence that the public-key formatted-digest
path and the separate digest-equality outcome are overridden.

The NDS-header-logo state patch must remain separate from those verification
stubs.  It changes the final transition of a confirmed state-`0x0C` handler after a timed write to
`REG_MASTER_BRIGHT` and `REG_MASTER_BRIGHT_SUB`; it proves a bypass of that
specific logo-comparison gate, but does **not** itself prove which user-visible
scene or warning-screen policy the wider state machine represents.

### Retained P1: normal-only alpha-transition edits

FlashMe V3's sole build, and the normal (non-stealth) builds from V4 onward,
patch Nintendo P1 as follows. The same logical sites use V3 offsets on Phat
and V6 offsets on Lite.

| Site | Byte-level transformation | Direct consequence |
| --- | --- | --- |
| first P1 main-loop dispatcher table entry | `0x0017` → `0x0023` | **[D/T]** The P1 reset/main loop invokes this dispatcher after initial setup. When its outer selector is zero, this first table case redirects from sub-engine alpha transition B to A. |
| transition-A comparison 1 | `cmp #0x0F` → `cmp #1` | **[D]** Reduces the threshold used by the original transition loop. |
| transition-A comparison 2 | `cmp #0x0F` → `cmp #1` | **[D]** Reduces the second threshold in the same sequence. |
| transition-A terminal branch | conditional branch → Thumb NOP | **[D]** Prevents the original terminal return at that branch and falls through into its continuation. |

The target routine writes `REG_BLDALPHA_SUB`, the sub-engine alpha-blend
coefficient register, not a master-brightness or backlight register.  Thus
**[D]** normal builds shorten/retarget a sub-screen alpha transition, while
stealth builds omit all four edits and retain the Nintendo V3/V6 bytes at these
sites. Two independent historical descriptions explicitly state that normal
FlashMe removes the Nintendo Logo and health/safety prompt, while
`FlashMe_Stealth` retains them ([GameBrew](https://www.gamebrew.org/wiki/FlashMe),
[HomeBrewGr](https://lnxt.gr/en/tutorials/post/howto-flashme-passmesuperpass/)).
Therefore **[D/H]** establishes the version-level display policy: stealth
shows the health prompt and normal does not. The four P1 edits alone still do
not identify which individual instruction controls a particular pixel stage.

**[E]** Project hardware comparison separates the two display behaviors: V1
normal first shows a non-stock black-to-white fade, then the health prompt; V3
normal retains that fade but no longer shows the prompt; V4 normal matches V3
normal; and V4 stealth skips the fade and shows the prompt after a near-stock
white-screen continuation. Thus “normal does not show the health prompt” never
means “normal does not perform the backlight fade.”

## Primary P1/P2: first-stage handoff and alternate boot paths

### V1–V4 primary pair

The V1/V3 primary P1 is a small ARM veneer.  It stores a supplied continuation
word through `r12`, loads a local handoff slot, and branches to it.  The V4
source preserves this primary-P1 shape.  Primary P2 switches to Thumb, uses
the existing firmware callback addresses kept in its literal pool, then
chooses one of two paths.

| Test / path | Direct behavior | Narrow functional conclusion |
| --- | --- | --- |
| `REG_KEYINPUT` low nibble is zero | **[D]** V1–V4 use `lsl r1,#28; beq p2_copy_boot`; because keys are active low, this means A+B+Select+Start are all held. | Selects the `p2_copy_boot` handoff. |
| GBA Game Code at `0x080000AC` equals `BOOT` | **[D]** The same `p2_copy_boot` path is selected after the key test. | A Slot-2 cartridge carrying Game Code `BOOT` can select that handoff without the four-key condition. |
| neither condition | **[D]** Reads the secondary FH, derives FP1/FP2 source and RAM destinations from its two descriptors, then invokes the BIOS7 LZ77 callback loader twice. | Reconstructs the retained FP1/FP2 layer and continues the ordinary firmware-side handoff. |

The path copies a three-word ARM9 handoff trampoline to `0x023FFE24`: the
first word is a target slot initially containing `0x023FFE28`, followed by
the ARM sequence `ldr r0,[pc,#-0xC]; bx r0` at `0x023FFE28`.  Thus it initially
branches to itself until another execution participant replaces the target
word.  Primary P2 stores the code entry (`0x023FFE28`) in the primary-P1
handoff slot and gives the final ARM7 `SVC_CpuFastSet` tail an `LR` of
`0x080000C0`.  **[D/T]** This proves an ARM9 wait/handoff trampoline plus an
ARM7 return to the Slot-2 program's conventional entry offset: an alternate
two-CPU Slot-2 boot route.  The writer that later releases the ARM9
trampoline is outside this compact primary pair, so no unsupported recovery
policy is attributed to it.  V5–V8 retain the same copied-trampoline shape.

### V5–V8 primary pair

V5 changes the primary P1 from a store-plus-branch veneer to a direct branch
through a local continuation slot.  Its primary P2 writes the continuation at
the corresponding new slot offset; V6, V7, and V8 keep that arrangement.  The
source also moves the **secondary FH location read by primary P2** (under the
historical but misleading symbol `FlashMePrimaryHeaderAddress`) from `0x3FC80`
to `0x3F680` and changes its header type-id configuration. These are **[D]**
layout and handoff changes.  The installer-side meaning of the primary-H
`1`→`2` category and the V5-and-later FH subversion byte is established below.

**[H]** This move avoids the first `0x400` bytes of the trailing `0x600`-byte
per-console area, which holds Wi-Fi access-point settings. Historical research
records that Mario Kart DS local demo/multiplayer testing exposed the old
`0x3FC80` layout's overwrite of those settings, prompting V5's `0x3F680`
location. The tail ownership and `0x600` address delta are directly checkable
from the build layout; the testing discovery itself is not a conclusion from
assembly control flow alone.

The V5–V8 P2 `BOOT` and A+B+Select+Start selection logic remains the same
direct pattern as V1–V4.  V7 changes neither of those primary-P2 tests; its
larger functional changes occur in FP1/FP2.

### V8a primary pair

V8a replaces both compact primary programs.  The new primary P1 is a command
loop: command `1` clears DMA control words, calls ARM9 `SVC #0x1F` with
`r0 = 1` (therefore `SVC_CustomPost` writes `1` to `REG_POSTFLG`), disables
power, configures/clears VRAM, sets WRAM ownership, clears OAM and palette
RAM, clears both main and sub `DISPCNT`, then clears the command word.

The V8a primary P2 selects its alternate route when **Start+Select** are both
held (active low) or when the Slot-2 Game Code is `BOOT`. It then:

1. writes command `1` to primary P1 and waits for the P1 loop to clear it;
2. reads `0x180` bytes beginning at firmware address `0x3FE00` into
   `0x023FFC80` through private BIOS7 `0x00002437`; this contains settings
   area 1 and the first `0x80` bytes of area 2. It compares their update
   counters (`+0x70` / `+0x170`) and, when area 2 is newer, copies its `0x80`-
   byte active-settings record over area 1 in RAM;
3. performs the same `SPICNT/SPIDATA` transaction described later, clears DMA,
   enables power, then invokes ARM7 `SVC_SoundBias` with a `0x3000` inter-step
   delay;
4. tests the BIOS7-maintained halfword at `0x027FF80C`: BIOS7
   `FUN_0000121A` initially marks it nonzero, then clears it only when the
   loaded Slot-1 header has both the expected Nintendo-logo CRC16 (`0xCF56`)
   and a matching header CRC16. A nonzero value selects the older Slot-2
   trampoline; zero selects the Slot-1 data-loading path.

For the Slot-1 path, the offsets read by P2 are
`+0x20/+0x24/+0x28/+0x2C` and `+0x30/+0x34/+0x38/+0x3C`: the ARM9 and ARM7 ROM
offset, entry address, RAM address, and size fields in libnds' `tNDSHeader`.
It emits `B7aaaaaaaa000000h`, the standard encrypted DS-card main-data command,
and reads `0x200`-byte chunks. The ARM9 transfer deliberately begins at ROM
`0x8000`—the lowest address permitted by that command—and adjusts destination
and length from the header's ARM9 ROM offset; it therefore leaves any ARM9
slice before `0x8000` to the prior boot state. The ARM7 transfer uses its header
ROM offset directly. Finally P2 writes the ARM9 entry address into primary P1's
command word, and P1's non-`1` command path branches to it while P2 branches to
the ARM7 entry. **[D/T]** This is an actual two-CPU handoff into a valid Slot-1
NDS program, not merely a header probe. The manual trigger and invalid-header
fallback are direct behavior; an author-level label such as “repair mode” is
still not required to describe the implementation.

### All primary P2 versions: streamed secondary-P12 decode path

The primary P2 secondary-layer loader is present in every recovered V1, V3–V8a
template.  V8a retains it beside its new alternate card route: when neither
**Start+Select** nor the `BOOT` Game Code chooses that route,
`p2_service_boot` uses the firmware image itself as a streamed source for the
BIOS7 LZ77 decoder:

1. It calls `0x00002437` to read the start of the FlashMe secondary **FH**
   header at `0x3F680` into its header workspace.  V1 through V8 request
   `0x70` bytes; V8a requests `0x40`, which still covers all fields used here.
2. It takes `FH+0x0C/+0x0E` for **FP1**, then `FH+0x10/+0x12` for **FP2**,
   together with the shift field at `FH+0x14`.  The two calculations produce
   the on-flash source position and the corresponding runtime destination
   below the FP1/FP2 RAM bases.  This field ownership agrees with the local
   [dsfwtool component reference](../../dsfwtool/README.md).
3. For each FP component, it enters BIOS7 `SVC_LZ77UnCompVRAM` at `0x00002A2B`
   with a three-word callback descriptor.  `p2_legacy_thunk` starts serial
   Flash `READ (0x03)` at the computed source address and primes the SPI
   transfer.  `p2_legacy_wait` waits for `SPICNT` to become idle, returns the
   received `SPIDATA` byte, and writes that byte back to clock the next one.
   The descriptor's final callback is BIOS7 `0x000022C7`.

The literal computation is also recoverable from P2: if `s = FH+0x14`, then
`FP1_source = FH+0x0C << (2 + (s & 7))` and
`FP1_destination = 0x02800000 - (FH+0x0E << (2 + ((s >> 3) & 7)))`.
For FP2 the corresponding shift groups are `s >> 6` and `s >> 9`, and the
destination base is `0x03810000`.  These are P2's own instructions, not a
formula inferred from layout alone.

**[D/T]** This is a custom serial-stream source for the BIOS LZ77 decoder,
not an ordinary RAM-to-RAM decompression call.  It is the runtime counterpart
of dsfwtool's unencrypted **FP1/FP2** P12/LZ10 model: every recovered primary
P2 secondary-layer path reconstructs those retained secondary components from the
firmware Flash before handing control back to the primary P1 path.  The old
names `PrimaryP2Legacy*` describe historical source labels only and should not
be read as evidence of a separate unknown compression format.

## FP1: ARM9 prefix lifecycle and hardware preparation

FP1 executes before retained Nintendo P1.  Its branches are governed by the
low nibble observed through `REG_IPC_SYNC`; the phase labels below are names
for literal values observed in code, not a reconstructed Nintendo protocol.

| Versions | Code-visible change | Established behavior |
| --- | --- | --- |
| V1 and V3 | `0x200`-byte prefix; waits until phase `>= 0xB`; `0xB` selects warm path, any higher phase selects cold path. | **[D]** Warm path writes `0x820F` to ARM9 `REG_POWERCNT` (enabling the LCD/display-engine bit set documented above) and waits for phase `0xD`; cold path clears DMA control, writes `1` to `REG_POSTFLG` through ARM9 `SVC_CustomPost`, clears video-related memory, sets WRAM control, clears OAM/palette, and installs/uses a return trampoline before entering retained P1. |
| V4 and V5 | Adds `BuildStealth` branches; removes the `SVC_CustomPost`/`REG_POSTFLG` write from the visible cold path. | **[D]** In stealth warm boot, FP1 jumps directly to retained P1; normal warm boot retains the power write and phase-`0xD` wait. |
| V6 | Restores the `SVC_CustomPost`/`REG_POSTFLG` write; changes the cold-path trampoline arrangement and adds a conditional header-area clear/copy. | **[D/T]** The configured base is `0x02800000`. If the BIOS7 Slot-1-header-validity mirror at `0x027FFFFC` is nonzero, FP1 clears `0x027FFE00..0x027FFF6F`, then `SVC #0x0C` copies `0xA0` bytes from ARM9 BIOS `0xFFFF0020` to `0x027FFEC0`. This leaves a zeroed header prefix plus the canonical Logo/CRC area; its first `0x9C` bytes are exactly the Nintendo-logo range retained P3 compares. The trigger is now established as invalid Slot-1-header state. Why that synthetic header remains useful after FlashMe separately forces the P3 comparison transition is still **[U]**. |
| V7 Old, V7 New, V8 | Prefix grows to `0x400`; phase logic distinguishes `<0xB`, `0xB`, `0xC`, and `>0xC`; normal warm path waits for `0xE`. | **[D/T]** Cold preparation first writes the all-disabled VRAMCNT pattern, clears LCDC-mapped VRAM, restores the ARM7 WRAM allocation, performs the same conditional `0xFFFF0020` → `0x027FFEC0` copy, and then signals phase `0xE`. |
| V8a | Retains the V7/V8 FP1 shape with the V8a primary stage. | **[D]** Cold preparation additionally writes zero to `0x04000000` and `0x04001000` (`REG_DISPCNT` and `REG_DISPCNT_SUB`). |

`BuildStealth` affects more than the retained-P1 alpha edits: it also removes
the normal warm-path phase wait, selects a direct retained-P1 handoff, and
skips the normal FP2 PWM backlight fade-in. The code therefore proves a
different boot timing/power sequence; combined with the **[E]** result above,
the version-level result is established as “no fade, health prompt retained.”

## FP2: ARM7 selection, FlashMe boot, retained-firmware path, and card loaders

### Common selection tests

The default FP2 selector is present from V1 through V8a when `BuildNoAuto` is
not enabled:

| Tested condition | Branch result | Evidence |
| --- | --- | --- |
| `<code>Select</code>` is held | retained-firmware path | **[D]** `tst r0,#KEY_SELECT; beq fp2_service_boot`; input is active low. `fp2_service_boot` is an analysis label, not a recovered author name. |
| `<code>A+B+X+Y</code>` are all held | FlashMe path | **[D]** A+B are tested in `REG_KEYINPUT`, X+Y in `REG_KEYXY`; both masked results must be zero. |
| Slot-2 Game Code is `PASS` | FlashMe path | **[D]** The 32-bit word at GBA header `+0x0C` is compared with the `PASS` literal. |
| Slot-2 Game Title begins `DSBooter` | FlashMe path | **[D]** The first eight title bytes at GBA header `+0x00` are compared with `DSBooter`. |
| none of the preceding | retained-firmware path in V1–V6 and V8; V7 initially probes a Slot-1 path first | **[D]** See the version-specific behavior below. |

`BOOT` is intentionally a separate test in primary P2, and is examined before
the `PASS`/`DSBooter` selector has control.  It enters the primary alternate
route described above; it should not be conflated with the ordinary FP2
FlashMe selection test.

### Common FlashMe and retained-firmware paths

The FlashMe path calls private BIOS7 `0x00002437` to read `0x180` bytes from
firmware address `0x3FE00` into `0x023FFC80`. This spans user-settings area 1
and the first `0x80` bytes of area 2. The halfwords at `+0x70` and `+0x170`
are their update counters; if area 2 is newer, BIOS CPUFastSet copies its
first `0x80` bytes (`0x20` words) over the RAM copy of area 1. The code then
clears DMA control, exchanges the expected ARM7/ARM9 phase values, and
branches to the configured ARM7 return. This is a concrete user-settings
selection and boot-handoff sequence, rather than an opaque header transfer.

At entry, every FP2 variant writes power control `1`, leaves a nonzero value
in `r0`, sets `r1 = 0x3000`, and invokes ARM7 `SVC #0x08`.  The supplied
BIOS7 implementation is `SVC_SoundBias`, so this raises `REG_SOUNDBIAS` one
step at a time toward `0x200`, waiting `0x3000` loop iterations between steps.

The standard normal retained-firmware path writes phase `0xB`, advances a counter from
`0x1000` toward `0x20000` in `0x1800` steps, and enters retained P2 after
writing its terminal phase. Each iteration waits, then uses BIOS7
`0x00002369` twice to write Power Management register 0: first `0x01`, then
`0x0D`. These values respectively enable the sound amplifier alone, and the
sound amplifier plus both backlights. After the first `0x0D` write, each cycle
leaves the backlights on for the growing `r5` delay, then turns them off for
the shrinking `0x20000 - r5` delay. GBATEK documents this on/off duty-cycle
method as backlight PWM dimming, so **[D/T]** the normal path implements a
backlight fade-in. Stealth variants do not execute that loop: after the
initial phase write they branch directly to retained P2, thereby skipping
this code-driven fade-in.

V4 first emits, in the FlashMe path, the two ARM7 SPI transactions:

```
REG_SPICNT = 0x8A00; REG_SPIDATA = 0x84;
wait for SPI busy clear;
REG_SPICNT = 0x8200; REG_SPIDATA = 0x00;
```

GBATEK assigns device-select value `2` to the touchscreen controller, so
`0x8A00` and `0x8200` are not merely SPI-shaped values: both select that
device, with the first transfer holding chip select.  The first byte, `0x84`,
has the TSC start bit, requests a 12-bit single-ended conversion on channel 0
(Temperature 0); the second clocks a zero byte while releasing the selection.
**[D]** The code never consumes the returned data, so it performs the exact
controller command sequence but does not take a useful temperature sample in
this visible range. **[U]** The code alone does not establish why FlashMe makes
that conversion/selection transaction. V4 omits the earlier explicit
private-BIOS `SignalBootFinish` call before it; V6 restores that call and
retains the two SPI transactions. `SignalBootFinish` writes byte `1` to
`REG_POSTFLG`, so this is a concrete difference in that flag write, not merely
a generic “boot return.” V7 and later retain that broad ordering as part of
their cold boot path. [GBATEK — NDS SPI and touchscreen controller](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md)

### V7 Slot-1 loader path

When V7's normal selector reaches neither a recognized `PASS`/`DSBooter`
header nor a forced FlashMe selection, it enters `fp2_aux_probe` rather than
immediately entering the retained-firmware path. Before the probe, it writes `0xA040`
to `REG_AUXSPICNT`. libnds defines that exact value as
`CARD_ENABLE | CARD_SPI_ENABLE | CARD_SPI_HOLD`: the Slot-1 card interface and
its auxiliary SPI bus are enabled, and auxiliary SPI chip select is held across
byte transfers. This establishes the bus used by the probe without assigning
an unsupported name to the peripheral at the other end.

The direct sequence is:

1. transfer `0xF2` on the auxiliary SPI interface and require subsequent
   responses `0x32` and `0x10`;
2. transfer `0xF1`, then read `0x200` bytes through the card/DMA path to
   `0x02100000`;
3. invoke `SVC #0x0E` with seed `0xFFFF` on `header + 0xC0` for `0x9C` bytes,
   and compare the result against `header + 0x15C`;
4. on success, DMA-transfer ARM9 fields at `+0x20/+0x28/+0x2C` and ARM7 fields
   at `+0x30/+0x38/+0x3C`, then branch to the ARM7 entry at `+0x34`;
5. on failure, send `0xF0` through the auxiliary interface and continue to the
   retained-firmware path.

The transfer uses the card-bus registers (`REG_CARD_COMMAND`, `REG_ROMCTRL`,
`REG_CARD_DATA_RD`) and configures `REG_ROMCTRL = 0xA9000000`. Per libnds this
sets `CARD_ACTIVATE | CARD_nRESET | CARD_CLK_SLOW | CARD_BLK_SIZE(1)`, where
block-size selector 1 is a `0x200`-byte block. Its card command is
`A4 00 aa aa aa 00 00 00`, not the standard `B7` main-data command: `A4` is
absent from libnds' list of standard card command constants. The offsets and
the CRC16 range are exactly the NDS header ARM9/ARM7 fields and Nintendo-logo
CRC field documented by libnds. Thus **[D/T]** V7 contains a device-specific
card-bus NDS-header loader that validates the logo CRC16 before launching the
loaded ARM9/ARM7 payloads. It must not be silently conflated with V8a's
standard `B7` Slot-1 loader.

The exact protocol remains deliberately unnamed. In particular, the official
libnds `card.h` list of standard auxiliary SPI EEPROM commands contains values
such as `0x01`, `0x02`, `0x03`, `0x05`, `0x06`, `0x9F`, `0xAB`, and `0xB9`, but
not `0xF0`, `0xF1`, or `0xF2`. The latter are therefore direct evidence of a
non-standard auxiliary-device handshake, not evidence by themselves for a
specific PassMe or cartridge implementation. Their high-level semantics beyond
the visible handshake are **[U]**.

Both V7 Old model families contain this loader.  V7 New Lite is code-identical
to V7 Old Lite for this prefix.  V7 New Phat adds a `BuildStealth`-only SPI
setup sequence before its cold handoff: it sends `0x84`, inspects response bit
`0x40`, and conditionally derives a follow-up control word from header byte
`+0x64`.  It also waits for the SPI response in the write helper.  The hardware
purpose of that model-specific setup remains **[U]**.

### V8 and V8a selector changes

V8 retains the V7 auxiliary/card helper bytes in FP2, but the top-level
selector no longer branches to `fp2_aux_probe`; a nonmatching GBA header goes
directly to `fp2_service_boot`.  Within the reconstructed FP2 prefix, no other
entry reaches those V7 loader helpers.  Therefore the helper bytes are present
but unreachable from the normal FP2 entry path in V8.

V8 also adds `BuildNoAuto`:

| Variant / version | Selector compiled at FP2 entry | Established user-input effect |
| --- | --- | --- |
| V8 normal or stealth | default selector above | `<code>A+B+X+Y</code>` and `PASS`/`DSBooter` can select the FlashMe path; held `<code>Select</code>` selects the retained-firmware path. |
| V8 noauto or stealth-noauto | only the A+B+X+Y test reaches `fp2_flash_boot`; the retained title/code test has no inbound edge | **[D]** All four keys must be held to select FlashMe; `PASS`/`DSBooter` no longer selects it automatically. |
| V8a normal or stealth | default selector above | Same default key/title/code behavior. |
| V8a noauto or stealth-noauto | `<code>Select</code>` held reaches `fp2_flash_boot`; released Select reaches the retained-firmware path | **[D]** The noauto manual trigger changes from A+B+X+Y to Select. |

V8 moves the firmware user-settings read/selection sequence into the retained-firmware
path as well as the cold FlashMe path. V8 Lite replaces the normal
power-management SPI write loop with a single ARM7 `SVC #0x03`
`SVC_WaitByLoop` delay (`r0 = 0x280000`) before its terminal phase and
retained-P2 handoff; therefore this normal V8 Lite FP2 path no longer performs
the earlier PWM backlight fade-in. Its settings-read routine additionally
performs the Lite SPI setup sequence. V8a keeps those corresponding Phat/Lite
FP2 choices; its major new card launch behavior is in primary P2, not the V8a
FP2 selector.

## Header-layer changes

Every reconstructed `patch_h.s` and `patch_fh.s` begins with the supplied
Nintendo header, fills `0x28..0x17B` with `0xFF` for the reproducible template,
and then writes the P1/P2 RAM-address fields.  `H` receives the primary P1/P2
addresses; `FH` receives FP1/FP2 addresses.  If a shift override is supplied,
both headers receive it.  Both headers set `+0x17E` to `0xFFFF` in this
reconstruction.

| FlashMe line | `H + 0x17C` | `FH + 0x17C` | installer classification | secondary FH location read by primary P2 | Directly observable change |
| --- | ---: | ---: | --- | ---: | --- |
| V1, V3, V4 | `1` | `1` | Legacy FlashMe; no individual V1–V4 number is decoded. | `0x3FC80` | Initial reconstructed layout family. |
| V5 | `2` | `2` | V5 (`2 + 3`) | `0x3F680` | Header location changes; this starts the installer V5+ subversion scheme. |
| V6 | `2` | `3` | V6 (`3 + 3`) | `0x3F680` | Installer V5+ subversion increments to V6. |
| V7 Old / V7 New | `2` | `4` | V7 (`4 + 3`) | `0x3F680` | FP prefix grows to `0x400`; Phat/Lite bases split. |
| V8 / V8a | `2` | `5` | V8 (`5 + 3`); this field does not distinguish V8a. | `0x3F680` | V8 variant selector and V8a primary-stage changes coexist with this marker pair. |

The table records literal data emitted by the build sources.  The local
FlashMe installer ARM7 source defines `MAJOR_VER = 0x17C` and
`MINOR_VER = BACKUPHEADER + 0x17C`.  Its recognition branch is explicit:
`H+0x17C == 1` reports the legacy FlashMe family, `== 2` reads
`FH+0x17C + 3` as the V5-or-later FlashMe version, `== 3` reports HB firmware,
and `== 0xFF` treats the image as the source Nintendo firmware.  Consequently,
the `FH+0x17C` sequence is not a runtime boot ABI: it is an installer-side
subversion field used only after primary-H type `2` has selected the V5+ path.
The V8 and V8a templates both carry `5`, so that recognition code reports both
as V8. This branch is reproduced verbatim by the supplied local installer
source and is independently visible in a public preservation copy of that
source; the latter corroborates the branch but is not evidence of original
authorship. [Installer ARM7 source, preservation copy](https://raw.githubusercontent.com/layeraudioai/flashme/master/arm7.c) · [independent firmware-format note](https://retroisle.com/others/nintendods/Technical/Firmware/dsfirmware.php)

The installer indexes `oldFW` as `u8 *`, so this is a **byte** classifier at
`+0x17C`. The reconstruction writes it with `.dh` solely because the header
slot is handled as a halfword elsewhere: all listed little-endian outputs have
the code byte at `+0x17C` and zero at `+0x17D`. This must not be mistaken for
a 16-bit version number.

Put another way, the exact decision tree is:

| `H+0x17C` | Installer classification | Does it read `FH+0x17C`? | Result shown by this installer |
| ---: | --- | --- | --- |
| `1` | legacy FlashMe family (the recovered V1/V3/V4 templates use this class) | No | `FM-??`; it does not distinguish V1–V4. |
| `2` | V5+ FlashMe | Yes | `FM-V(FH+0x17C+3)`. |
| `3` | HB firmware | No | `HB`. |
| `0xFF` | source Nintendo firmware | No | the separately derived source-firmware version string. |
| other | unrecognised | No | `?`. |

Thus, `FH+0x17C=2/3/4/5` has the version meanings V5/V6/V7/V8 only inside
the `H+0x17C=2` branch.  It is not a general FH version field and cannot by
itself identify V1–V4, HB firmware, or V8a.

This is also consistent with the boot code: recovered primary P2 programs
read only the first `0x70` bytes of FH (V8a: `0x40`) for their FP1/FP2
descriptors.  None reaches `FH+0x17C`; that field is installer metadata, not
part of the primary boot loader's live descriptor ABI.

The supplied HBFirmware builder independently assigns `H+0x17C = 3` and
documents the adjacent categories as `1 = old FlashMe` and `2 = FlashMe` (with
one snapshot qualifying `1` as pre-MK / Wi-Fi unsafe).  The reconstructed
primary values match that convention exactly: V1/V3/V4 use `1`, and V5 onward
use `2`. [HBFirmware builder](../../flashme-old/hbfirmware-090807/hbfirmware/installer/arm9/source/makebootstrap.c)

The same builder names `H+0x17E` the preserved old CRC that identifies the
source Nintendo firmware version.  If the incoming field is `0xFFFF`, it
falls back to the incoming `H+0x06` P1/P2 CRC16 before replacing P1/P2.  That
establishes the field's construction-time convention, while the reconstructed
templates deliberately keep it at `0xFFFF` along with the sanitized private
header range.

## Version-to-version change record

This is a change matrix, not a release-note chronology.  Each row describes
what the actual reconstructed sources add or remove relative to the preceding
available line.

| Version line | Source-level delta | Established functional consequence |
| --- | --- | --- |
| V1 | Introduces the two-layer P1/P2 and FP1/FP2 construction; patches the V3 P1 P3/P4-combined and P5 CRC16 gates, plus V3 P3 final-state/verification/digest entries. | **[D/T]** Installs alternate primary/FP handoffs, bypasses the two traced CRC16 gates, and forces success from the two P3 verification-related entries. Its normal FP2 path already contains the PWM backlight fade-in. It does **not** contain the later four retained-P1 alpha-transition edits. |
| V2 | No original template or source is available. | Excluded; no behavioral reconstruction is asserted. |
| V3 | Adds the four normal-only retained-P1 alpha-transition edits; uses the V1-style primary and FP staging. | **[D]** Normal V3 alters the first alpha-transition dispatch and threshold/terminal behavior; V1 did not.  The specific UI scene remains unresolved. |
| V4 | Adds `BuildStealth` alternatives in FP1/FP2 and retains the normal-only P1 alpha edits; omits the cold FlashMe path's explicit `SignalBootFinish`/`REG_POSTFLG` byte write while adding the two SPI transactions. | **[D/T]** Stealth changes warm/retained-firmware handoff behavior, skips the normal PWM backlight fade-in, and leaves the P1 alpha range unmodified; normal retains the V3 P1 changes. The SPI sequence is newly present. |
| V5 | Changes primary P1/P2 handoff-slot layout and moves the secondary FH location read by primary P2 from `0x3FC80` to `0x3F680`; otherwise retains V4-style normal/stealth FP behavior. | **[D/H]** New primary metadata/handoff positions are used, and the installer enters its `H=2` / `FH+3` V5+ version-recognition scheme; historical research attributes the move to avoiding overwrite of trailing Wi-Fi access-point settings. |
| V6 | Restores the FP1 `SVC_CustomPost`/`REG_POSTFLG` write and adds the conditional FP1 clear/copy; restores `SignalBootFinish` before the SPI sequence; increments the installer V5+ subversion field to `3` (V6). | **[D]** The described FP1 memory preparation and FP2 call ordering change.  This FlashMe V6 Phat line still embeds the Nintendo V3 retained code base. |
| V7 Old | Enlarges FP prefixes to `0x400`, changes FP1 IPC phases, introduces Phat/Lite families, and adds the reachable Slot-1 header loader in FP2. | **[D/T]** Direct card-header validation and ARM9/ARM7 launch are added; Lite uses Nintendo V6 P1/P2/P3 offsets and Phat uses Nintendo V3 offsets. |
| V7 New | Keeps the V7 Old Lite FP prefixes unchanged; changes the Phat FP2's SPI setup/response handling for the stealth cold path and SPI write helper. | **[D]** Only the indicated Phat setup/wait behavior changes within the analysed prefixes. |
| V8 | Adds `BuildNoAuto`; removes all entry-path calls to the V7 FP2 auxiliary/card loader while retaining its dead helper bytes; moves user-settings read/selection into the retained-firmware path; changes Lite normal retained-firmware pacing. | **[D/T]** V8 noauto requires A+B+X+Y, normal V8 no longer reaches the V7 FP2 Slot-1 loader from its entry path, and normal V8 Lite replaces the earlier FP2 PWM backlight fade-in with a delay. |
| V8a | Replaces the primary P1/P2 pair with a command-driven preparation stage and standard Slot-1 NDS-program loader; changes noauto trigger to Select; adds display-control clearing in FP1 cold preparation. | **[D/T]** Start+Select/`BOOT` enters the V8a primary alternate route. After the BIOS-maintained Slot-1 header-validity test, it either takes the older Slot-2 trampoline or uses standard `B7` data reads and the header's ARM9/ARM7 fields to hand both CPUs to a Slot-1 NDS program; V8a noauto Select chooses FlashMe. |

## Facts that remain unresolved

The following are deliberately retained as open questions rather than forced
into a feature name:

- Which exact user-visible Nintendo screen/state is represented by the P3
  state-`0x0C` Nintendo-logo-gated transition, introduced in **V1** and
  retained later, which writes state value `0x0D`. The control flow is known,
  but this local change does not yet establish that V1 actually removes the
  health/safety screen.
- Which user-visible screen is represented by the normal retained-P1
  sub-engine alpha-transition range added only in **V3**, and whether it forms
  one display policy with the earlier V1 P3 change. The registers and local
  control flow are known, but the two edits cannot automatically be combined
  into a proven health-screen patch.
- The high-level policy purpose of the primary-P2 streamed firmware decode
  route.  Its serial `READ`, LZ77 callback ABI, FP1/FP2 field use, and handoff
  are established; whether the author regarded this route as service,
  recovery, or an ordinary boot fallback is not.
- The high-level protocol meaning of V7's auxiliary `0xF2`/`0xF1`/`0xF0`
  commands and the Phat/Lite SPI setup response bit.  The command bytes,
  conditional branches, and subsequent loader actions are established; the
  peripheral protocol's author-level purpose is not.
- Why V8a exposes the standard Slot-1/Slot-2 alternate boot selection through
  **Start+Select** and the `BOOT` Game Code. Its concrete header-validity test,
  data transfers, and two-CPU handoff are established; only the author's
  policy rationale remains unproven.
- Why V6-and-later FP1 synthesizes a blank-header prefix plus BIOS Logo after
  BIOS7 has marked the Slot-1 header invalid, even though the retained P3
  logo-comparison branch is separately forced to its success transition. The
  trigger and resulting RAM layout are known; the wider retained-memory policy
  is not.

## Evidence references

- [Nintendo V3/V6 semantic map](../official/SEMANTIC_MAP.md) — exact runtime
  locations, source labels, and byte-level P1/P3 modifications used here.
- [Nintendo listing export notes](../official/README.md) — recovered P1–P5
  runtime ranges, including the P3 base validation used by the patch sources.
- [GBATEK](https://doc.kodewerx.org/documents/gbatek.html) — NDS I/O, IPC,
  BIOS, keypad, SPI, and card-interface reference.
- [libnds input definitions](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/input.h)
  and [key scan implementation](https://raw.githubusercontent.com/devkitPro/libnds/master/source/arm9/keys.c)
  — active-low key interpretation.
- [libnds video definitions](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/arm9/video.h)
  and [ARM7 serial definitions](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/arm7/serial.h)
  — named display and SPI constants; touchscreen-command semantics are taken
  directly from GBATEK.
- [libnds NDS header layout](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/memory.h)
  and [card definitions](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/card.h)
  — the field offsets used by V7 FP2 and V8a P2 card loaders.
- [dsfwtool component/layout reference](../../dsfwtool/README.md) — independent
  cross-check of H/P1–P5/FH/FP1/FP2 storage layers and P12/P345 treatment.
- Supplied [BIOS7 listing](../../ndsbios/bios7.s) and
  [BIOS9 listing](../../ndsbios/bios9.s) — locally inspected SVC tables and
  private BIOS entry behavior used above.

The linked external documentation is used to name hardware and ABI fields.
All FlashMe-version claims in this file are grounded in the local reconstructed
assembly, rather than historical release descriptions.
