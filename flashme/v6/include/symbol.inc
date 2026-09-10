// FlashMe V6 Phat target symbols.
//
// This file deliberately separates immutable Nintendo DS addresses from the
// values chosen by this FlashMe build.  Change only the final section when
// porting the patch; ShiftAmountsOverride is the explicit format-level option.

// -----------------------------------------------------------------------------
// Nintendo DS hardware memory map and I/O registers (platform-fixed)
// -----------------------------------------------------------------------------

// I/O registers.
.definelabel REG_KEYINPUT,                  0x04000130
.definelabel REG_KEYXY,                     0x04000136
.definelabel REG_IPC_SYNC,                  0x04000180
.definelabel REG_SPICNT,                    0x040001c0
.definelabel REG_SPIDATA,                   0x040001c2
.definelabel REG_DMA0SAD,                   0x040000b0
.definelabel VRAM_A_CR,                     0x04000240
.definelabel WRAM_CR,                       0x04000247
.definelabel REG_POWERCNT,                  0x04000304

// libnds-style keypad bits used by this patch.  KEY_A, KEY_B, and KEY_SELECT
// are raw active-low bits of REG_KEYINPUT.  libnds presents X/Y in its combined
// keypad state as bits 10/11, whereas the ARM7-only raw REG_KEYXY register
// exposes their active-low state in bits 0/1; KEYXY_X/KEYXY_Y name those raw
// register-local masks explicitly.
// 本补丁使用的 libnds 风格按键位。KEY_A、KEY_B 与 KEY_SELECT 是 REG_KEYINPUT 的
// 原始低有效位。libnds 在合并后的按键状态中把 X/Y 表示为第 10/11 位，而仅 ARM7 可读的
// 原始 REG_KEYXY 寄存器则在第 0/1 位提供它们的低有效状态；KEYXY_X/KEYXY_Y 明确表示
// 这两个仅适用于原始寄存器的掩码。
.definelabel KEY_A,                         (1 << 0)
.definelabel KEY_B,                         (1 << 1)
.definelabel KEY_SELECT,                    (1 << 2)
.definelabel KEY_X,                         (1 << 10)
.definelabel KEY_Y,                         (1 << 11)
.definelabel KEYXY_X,                       (1 << 0)
.definelabel KEYXY_Y,                       (1 << 1)

// libnds-style LCDC aliases for the nine physical VRAM banks.  When all banks
// use LCDC mode, their 128K*4 + 64K + 16K*2 + 32K + 16K capacity is contiguous.
.definelabel VRAM_A,                        0x06800000
.definelabel VRAM_B,                        0x06820000
.definelabel VRAM_C,                        0x06840000
.definelabel VRAM_D,                        0x06860000
.definelabel VRAM_E,                        0x06880000
.definelabel VRAM_F,                        0x06890000
.definelabel VRAM_G,                        0x06894000
.definelabel VRAM_H,                        0x06898000
.definelabel VRAM_I,                        0x068a0000
.definelabel VramLcdcBytes,                 0x000a4000

// These libnds-style bases cover both 2D engines when paired with the size
// fields below: 1 KiB main + 1 KiB sub.
.definelabel BG_PALETTE,                    0x05000000
.definelabel MM_PALRAM_SZ,                  0x00000800
.definelabel OAM,                           0x07000000
.definelabel MM_OBJRAM_SZ,                  0x00000800
.definelabel GBAROM,                        0x08000000
.definelabel GbaRomTitleAddress,            GBAROM + 0x0a0

// libnds VRAM configuration fields used by the ARM9 bootstrap.
.definelabel VRAM_ENABLE,                   (1 << 7)
.definelabel VRAM_A_LCD,                    0x00
.definelabel VRAM_B_LCD,                    0x00
.definelabel VRAM_C_LCD,                    0x00
.definelabel VRAM_D_LCD,                    0x00

// Project-defined in the same style as libnds' VRAM mode names: ARM7 owns
// the entire 32 KiB shared WRAM region.  libnds exposes WRAM_CR but no name
// for this field value.
.definelabel WRAM_0KARM9_32KARM7,           0x03

// Four byte-wide VRAMCNT configurations for the A-D register block.  The
// subsequent halfword and byte stores reuse the same enabled-LCDC byte for
// banks E-I.
.definelabel VramLcdcEnableAbcd,            (VRAM_ENABLE | VRAM_A_LCD) | ((VRAM_ENABLE | VRAM_B_LCD) << 8) | ((VRAM_ENABLE | VRAM_C_LCD) << 16) | ((VRAM_ENABLE | VRAM_D_LCD) << 24)

// -----------------------------------------------------------------------------
// Nintendo DS BIOS ABI (fixed for the retail BIOS expected by this target)
// -----------------------------------------------------------------------------

// DS BIOS dispatches the SWI number from bits 16-23 of an ARM SWI instruction.
.definelabel SwiArm7WaitByLoopImmediate,    0x00030000
.definelabel SwiArm7SoundBiasImmediate,     0x00080000
.definelabel SwiArm7CpuFastSetImmediate,    0x000c0000

// ARM7 BIOS routines used by the bootstrap.  These are BIOS dependencies,
// not addresses selected by FlashMe's component layout.
.definelabel BiosCopyRoutine,               0x00002437
.definelabel BiosIpcSendRoutine,            0x00002369
.definelabel BiosBootReturnRoutine,         0x0000119d
.definelabel PrimaryP2ComputeRoutine,       0x000030e4
.definelabel PrimaryP2SwiRoutine,           0x00002369
.definelabel PrimaryP2LegacyCallRoutine,    0x00002389
.definelabel PrimaryP2LegacyCopyRoutine,    0x000033a5
// Historical primary-P2 pool word retained between the Thumb callback entries.
// Its exact ABI role has not yet been recovered, so it is intentionally named
// as a value rather than misidentified as a BIOS function.
// 历史一级 P2 pool 字，保留在 Thumb 回调入口之间。其准确 ABI 作用尚未恢复，因此
// 有意按“值”命名，而不会误标为 BIOS 函数。
.definelabel PrimaryP2LegacyCallbackValue,  0x000022c7

// -----------------------------------------------------------------------------
// Nintendo DS firmware-image layout and header encoding (format-fixed)
// -----------------------------------------------------------------------------

.definelabel FirmwareHeaderSize,            0x180
.definelabel HeaderPart12Crc16Offset,       0x006
.definelabel HeaderPart1RamaddrOffset,      0x00e
.definelabel HeaderPart2RamaddrOffset,      0x012
.definelabel HeaderShiftAmountsOffset,      0x014

// The part*_ramaddr fields encode a RAM address relative to these format
// bases; they are not the runtime addresses selected by FlashMe below.
.definelabel FirmwarePart1RamaddrBase,      0x02800000
.definelabel FirmwarePart2RamaddrBase,      0x03810000

// V6 Phat keeps the official V3 code bodies but changes the output descriptor
// units to 0x0C71.  This controls the 8-byte component alignment and the RAM
// address fields of both H and FH; it is intentionally distinct from the
// source-H value used to decode retained retail entry addresses.
// V6 Phat 会保留官方 V3 的代码主体，但把输出描述符单位改为 0x0C71。它控制 H/FH
// 的 8 字节组件对齐与 RAM 地址字段，并有意与用于解码保留零售入口的源 H 数值区分。
.definelabel ShiftAmountsOverride,          0x0c71
.definelabel SourceShiftAmounts,            readu16("temp/h.bin", HeaderShiftAmountsOffset)
.definelabel EffectiveShiftAmounts,         ShiftAmountsOverride < 0 ? SourceShiftAmounts : ShiftAmountsOverride
.expfunc Part1RamaddrFromRam(address), (FirmwarePart1RamaddrBase - (address)) >> (2 + ((EffectiveShiftAmounts >> 3) & 7))
.expfunc Part2RamaddrFromRam(address), (FirmwarePart2RamaddrBase - (address)) >> (2 + ((EffectiveShiftAmounts >> 9) & 7))

// Decode the retail P1/P2 runtime entries from the source H before adding the
// FlashMe prefixes.  These use SourceShiftAmounts deliberately: a requested
// output-format override must not change where the retained retail bodies run.
// 从源 H 解码零售 P1/P2 的运行入口，再添加 FlashMe 前置代码。这里刻意使用
// SourceShiftAmounts：请求的输出格式覆写不应改变保留零售主体的运行地址。
.expfunc Part1RamFromSourceField(field), FirmwarePart1RamaddrBase - ((field) << (2 + ((SourceShiftAmounts >> 3) & 7)))
.expfunc Part2RamFromSourceField(field), FirmwarePart2RamaddrBase - ((field) << (2 + ((SourceShiftAmounts >> 9) & 7)))
.definelabel RetailP1RamAddress,            Part1RamFromSourceField(readu16("temp/h.bin", HeaderPart1RamaddrOffset))
.definelabel RetailP2RamAddress,            Part2RamFromSourceField(readu16("temp/h.bin", HeaderPart2RamaddrOffset))

// -----------------------------------------------------------------------------
// FlashMe target layout and identity (patch-defined; change when porting)
// -----------------------------------------------------------------------------

// "Primary" is the replacement P1/P2 named by H; "FlashMe" is the secondary
// FP1/FP2 pair named by FH.  These are plain RAM entry addresses, not header
// encodings.  The placement policy derives every component entry from a
// source entry or an explicitly sized staging region; it does not embed the
// four final RAM addresses as literals.
// “Primary” 是 H 指向的替换 P1/P2；“FlashMe” 是 FH 指向的二级 FP1/FP2 对。
// 它们都是普通 RAM 入口而非头编码。该布局策略会从源入口或显式大小的暂存区推导
// 每个组件入口，不会把四个最终 RAM 地址直接写成字面量。
.definelabel FlashMePrefixBytes,            0x200

// BuildStealth is supplied by the V6 Makefile: zero selects the normal build,
// one selects Stealth.  Both variants retain the same official V3 bodies and
// runtime component layout; only their FlashMe-owned prefix policy differs.
// BuildStealth 由 V6 Makefile 传入：零为常规版，一为 Stealth。两种变体保留相同的
// 官方 V3 主体与运行时组件布局；只有 FlashMe 自有前置代码的策略不同。

// The retained retail P1 occupies the upper 2 MiB ARM9 region in the supported
// DS source images.  Reserve the 64 KiB page immediately below that region for
// the small primary P1 gate.  The compatibility check below requires FP1's
// prefix to begin above this staging page.
// 受支持的 DS 源镜像会把保留的零售 P1 放在 ARM9 的高 2 MiB 区域。此处在该区域
// 正下方保留一个 64 KiB 页，供很小的一级 P1 等待闸门使用；即使零售 P1 入口在该
// 高位区域内移动，它仍与 FP1 分离。
.definelabel PrimaryP1StagingPageBytes,     0x00010000
.expfunc Arm9RetailRegionFloor(address),    (address) & 0xffe00000
.definelabel PrimaryP1StagingRegionEnd,     Arm9RetailRegionFloor(RetailP1RamAddress)
.definelabel PrimaryP1RamAddress,           PrimaryP1StagingRegionEnd - PrimaryP1StagingPageBytes
// V6 stores P1's self-loop / ARM9-release literal at +0x08.  Primary P2 uses
// the same offset for both its Slot-2 and FH loader paths.
// V6 将 P1 的自循环 / ARM9 放行字面量放在 +0x08。一级 P2 的 Slot-2 路径与
// FH 加载路径都会使用同一个偏移。
.definelabel PrimaryP1ReleaseSlotOffset,   0x0008

// The ARM7 primary P2 occupies the 2 KiB bootstrap window immediately below
// the part-2 format base.  This is the same base-minus-window relationship used
// by the historical bootstrap builder, while leaving the final address derived.
// 一级 ARM7 P2 占用 P2 格式基址正下方的 2 KiB 引导窗口。它沿用历史引导构建器的
// “基址减窗口”关系，因此最终地址由计算得出。
.definelabel PrimaryP2StagingWindowBytes,   0x00000800
.definelabel PrimaryP2RamAddress,           FirmwarePart2RamaddrBase - PrimaryP2StagingWindowBytes

// Each FP prefix ends exactly at the retail entry decoded from source H.  A
// port that changes its prefix area changes this single size, and both FH RAM
// entries follow automatically.
// 每个 FP 前置区都恰好在从源 H 解码出的零售入口处结束。移植时只要改变此前置区大小，
// FH 中两个 RAM 入口便会自动随之更新。
.definelabel FlashMeFp1RamAddress,          RetailP1RamAddress - FlashMePrefixBytes
.definelabel FlashMeFp2RamAddress,          RetailP2RamAddress - FlashMePrefixBytes

.if FlashMeFp1RamAddress < PrimaryP1StagingRegionEnd
    .error "FlashMe: FP1 prefix overlaps the dynamic primary P1 staging page"
.endif

// FlashMe-owned header-tail fields.  +0x17c selects the FlashMe type; +0x17e
// preserves the original P1/P2 CRC16 marker rather than an official field.
.definelabel HeaderTypeOffset,              0x17c
.definelabel HeaderOriginalVersionOffset,   0x17e
.definelabel PrimaryTypeId,                 0x0002
.definelabel FlashMeTypeId,                 0x0003

// Canonical 256 KiB image layout and its private ARM9 hand-off state.
.definelabel FlashMeFirmwareBytes,          0x0003fe00
// V6 reads FH from image +0x3F680.  Its ARM7 header work buffer remains at
// 0x023FFC80, matching the retained second-stage prefix ABI.
// V6 从镜像 +0x3F680 读取 FH。ARM7 的头工作缓冲区仍位于 0x023FFC80，从而保持
// 二级前置代码既有的 ABI。
.definelabel FlashMePrimaryHeaderAddress,   0x0003f680
.definelabel FlashMeHeaderRamAddress,       0x023ffc80
.definelabel Arm9ReturnSlot,                0x027ffe24
.definelabel Arm9ReturnSlotNext,            0x027ffe28
.definelabel Arm9ReturnSlotFp2,             0x027ffe34
.definelabel Arm9BootState,                 0x0000820f
.definelabel Arm7ReturnEntry,               0x080000c0

// FP1's V6 context installs a two-word ARM9 trampoline.  Its code first
// publishes IPC phase D, then reloads the preserved ARM9 continuation.  The
// Stealth B route is shorter, so it uses an earlier context location.
// FP1 的 V6 上下文会安装一个双字 ARM9 跳板：先发布 IPC 阶段 D，再重新载入已保存的
// ARM9 续接地址。Stealth 的 B 路径更短，因此它使用更靠前的上下文位置。
.if BuildStealth
    .definelabel Fp1ContextOffset,          0x11c
    .definelabel Fp2BootStateOffset,        0x074
.else
    .definelabel Fp1ContextOffset,          0x138
    .definelabel Fp2BootStateOffset,        0x0d8
.endif
.definelabel Arm9ReturnTrampolineAddress,   0x027fff70
.definelabel Fp1TrampolinePublishD,         0xe1c780b0
.definelabel Fp1TrampolineReloadReturn,     0xe599f000
.definelabel Fp1IpcPhaseD,                  0x00000d00
.definelabel Fp1ClearSourceAddress,         0xffff0020
