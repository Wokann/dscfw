// FlashMe V8a Phat symbols.
//
// The first three sections are Nintendo DS format/ABI constants.  The final
// section contains the FlashMe V8a placement and policy values.  Keeping the
// two classes separate makes it clear which values may vary when porting.
//
// 前三部分是 Nintendo DS 格式/ABI 固定值；最后一部分才是 FlashMe V8a 的布局与
// 策略值。二者分开可明确区分移植时哪些数值可以改变。

// -----------------------------------------------------------------------------
// Nintendo DS hardware map and BIOS ABI (platform-fixed)
// -----------------------------------------------------------------------------
.definelabel REG_KEYINPUT,                  0x04000130
.definelabel REG_KEYXY,                     0x04000136
.definelabel REG_IPC_SYNC,                  0x04000180
.definelabel REG_AUXSPICNT,                 0x040001a0
.definelabel REG_SPICNT,                    0x040001c0
.definelabel REG_SPIDATA,                   0x040001c2
.definelabel REG_DMA0SAD,                   0x040000b0
.definelabel REG_GCDATAIN,                  0x04100010
.definelabel REG_POWERCNT,                  0x04000304
.definelabel VRAM_A_CR,                     0x04000240

.definelabel VRAM_A,                        0x06800000
.definelabel BG_PALETTE,                    0x05000000
.definelabel OAM,                           0x07000000
.definelabel MM_PALRAM_SZ,                  0x00000800
.definelabel MM_OBJRAM_SZ,                  0x00000800
.definelabel VramLcdcBytes,                 0x000a4000
.definelabel WRAM_0KARM9_32KARM7,           0x03
.definelabel VramLcdcDisableAll,            0x80808080

.definelabel KEY_A,                         (1 << 0)
.definelabel KEY_B,                         (1 << 1)
.definelabel KEY_SELECT,                    (1 << 2)
.definelabel KEYXY_X,                       (1 << 0)
.definelabel KEYXY_Y,                       (1 << 1)

.definelabel SwiArm7WaitByLoopImmediate,   0x00030000
.definelabel SwiArm7SoundBiasImmediate,    0x00080000
.definelabel SwiArm7CpuFastSetImmediate,   0x000c0000
.definelabel BiosCopyRoutine,               0x00002437
.definelabel BiosIpcSendRoutine,            0x00002369
.definelabel BiosBootReturnRoutine,         0x0000119d
.definelabel PrimaryP2ComputeRoutine,       0x000030e4
.definelabel PrimaryP2LegacyEntry,          0x00002a2b
.definelabel PrimaryP2LegacyCallRoutine,    0x00002389
.definelabel PrimaryP2LegacyCopyRoutine,    0x000033a5
.definelabel PrimaryP2LegacyCallbackValue,  0x000022c7

// -----------------------------------------------------------------------------
// Nintendo DS firmware descriptor format (format-fixed)
// -----------------------------------------------------------------------------
.definelabel FirmwareHeaderSize,            0x00000180
.definelabel HeaderPart12Crc16Offset,       0x0006
.definelabel HeaderPart1RamaddrOffset,      0x000e
.definelabel HeaderPart2RamaddrOffset,      0x0012
.definelabel HeaderShiftAmountsOffset,      0x0014
.definelabel FirmwarePart1RamaddrBase,      0x02800000
.definelabel FirmwarePart2RamaddrBase,      0x03810000

// Official V8a writes 0x0c71 into both headers.  The retained V3 payloads
// stay at their original runtime addresses; descriptor fields are re-encoded
// under these V8a units.
// 官方 V8a 会向两份头写入 0x0c71。保留的 V3 载荷仍位于原运行时地址；
// 描述符字段则按这套 V8a 单位重新编码。
.definelabel ShiftAmountsFlashMe,           0x0c71
.definelabel ShiftAmountsOriginal,          -1
.definelabel ShiftAmountsOverride,          ShiftAmountsFlashMe
.definelabel SourceShiftAmounts,            readu16("temp/h.bin", HeaderShiftAmountsOffset)
.definelabel EffectiveShiftAmounts,         ShiftAmountsOverride < 0 ? SourceShiftAmounts : ShiftAmountsOverride
.expfunc Part1RamaddrFromRam(address), (FirmwarePart1RamaddrBase - (address)) >> (2 + ((EffectiveShiftAmounts >> 3) & 7))
.expfunc Part2RamaddrFromRam(address), (FirmwarePart2RamaddrBase - (address)) >> (2 + ((EffectiveShiftAmounts >> 9) & 7))
.expfunc Part1RamFromSourceField(field), FirmwarePart1RamaddrBase - ((field) << (2 + ((SourceShiftAmounts >> 3) & 7)))
.expfunc Part2RamFromSourceField(field), FirmwarePart2RamaddrBase - ((field) << (2 + ((SourceShiftAmounts >> 9) & 7)))
.definelabel RetailP1RamAddress,            Part1RamFromSourceField(readu16("temp/h.bin", HeaderPart1RamaddrOffset))
.definelabel RetailP2RamAddress,            Part2RamFromSourceField(readu16("temp/h.bin", HeaderPart2RamaddrOffset))

// -----------------------------------------------------------------------------
// FlashMe V8a placement, state, and identity (patch-defined)
// -----------------------------------------------------------------------------
.definelabel FlashMePrefixBytes,            0x00000400
.definelabel PrimaryP1StagingPageBytes,     0x00010000
.expfunc Arm9RetailRegionFloor(address),    (address) & 0xffe00000
.definelabel PrimaryP1RamAddress,           Arm9RetailRegionFloor(RetailP1RamAddress) - PrimaryP1StagingPageBytes
.definelabel PrimaryP1CommandAddress,       PrimaryP1RamAddress + 4
.definelabel PrimaryP2RamAddress,           FirmwarePart2RamaddrBase - 0x00000800
.definelabel FlashMeFp1RamAddress,          RetailP1RamAddress - FlashMePrefixBytes
.definelabel FlashMeFp2RamAddress,          RetailP2RamAddress - FlashMePrefixBytes

.definelabel PrimaryP1Bytes,                0x000000fc
.definelabel PrimaryP1PoolOffset,           0x000000e8
.definelabel PrimaryP2CardTransferOffset,   0x000000ce
.definelabel PrimaryP2BootParametersOffset, 0x000000fc
.definelabel PrimaryP2ServiceOffset,        0x00000128
.definelabel PrimaryP2LegacyThunkOffset,    0x00000172
.definelabel PrimaryP2LegacyWaitOffset,     0x00000190
.definelabel PrimaryP2LegacyPoolOffset,     0x000001a0
.definelabel PrimaryP2PoolOffset,           0x00000218

.definelabel FlashMeFirmwareBytes,          0x0003fe00
.definelabel FlashMePrimaryHeaderAddress,   0x0003f680
.definelabel FlashMeHeaderRamAddress,       0x023ffc80
.definelabel PrimaryHeaderCompareAddress,   0x023ffcf0
.definelabel SecondaryHeaderCompareAddress, 0x023ffdf0
.definelabel RecoveryStateAddress,           0x027ff800
.definelabel CardTransferContextAddress,    0x027ffe00
.definelabel RecoveryCopySource,            0x023ff800
.definelabel RecoveryCopyDestination,       0x023ffc00
.definelabel CardReadCommandBase,           0xa1000000
.definelabel P2DelayUnits,                  0x00000400
.definelabel PrimaryP2CardControlAddress,   0x040001a4
.definelabel SpiCommandFirstControl,        0x00008a00
.definelabel SpiCommandSecondControl,       0x00008200

.definelabel Arm9TrampolineAddress,         0x023ffe28
.definelabel Arm9TrampolineTargetAddress,   0x023ffe24
.definelabel Arm9ReturnSlot,                0x027ffe24
.definelabel Arm9ReturnSlotFp2,             0x027ffe34
.definelabel Arm9UnknownReturnSlot,         0x02100024
.definelabel Arm9ReturnTrampolineAddress,   0x027fff70
.definelabel Arm9BootState,                 0x0000820f
.definelabel Arm7ReturnEntry,               0x080000c0
.definelabel Fp1ClearSourceAddress,         0xffff0020
.definelabel PrimaryP2GbaEntryAddress,      0x080000ac
.definelabel GbaRomTitleAddress,            0x080000a0
.definelabel FlashMeAuxSpiControl,          0x0000a040
.definelabel DmaCardCopyControl,            0xaf000001
.definelabel PhatSpiInitialControl,         0x00008802
.definelabel PhatSpiFollowupControl,        0x00008002

.definelabel HeaderTypeOffset,              0x017c
.definelabel HeaderOriginalVersionOffset,   0x017e
.definelabel PrimaryTypeId,                 0x0002
.definelabel FlashMeTypeId,                 0x0005

// V8a adds five ARM instructions before FP1's zero routine, so its literal
// pool is 0x14 bytes later than V8's corresponding prefix.
// V8a 在 FP1 清零例程前新增五条 ARM 指令，因此字面量池比 V8 对应前置区晚 0x14。
.if BuildStealth
    .definelabel Fp1ContextOffset,          0x0054
    .definelabel Fp1ColdPrepareOffset,      0x006c
    .definelabel Fp1PoolOffset,             0x0164
.else
    .definelabel Fp1ContextOffset,          0x0070
    .definelabel Fp1ColdPrepareOffset,      0x0088
    .definelabel Fp1PoolOffset,             0x0180
.endif

// FP2 has a smaller NoAuto dispatch block.  The retained title-test code and
// all later helpers remain in the image, merely moving 0x0c bytes earlier.
// FP2 的 NoAuto 分派块更小；保留标题测试与后续帮助代码仍在镜像中，只整体前移 0x0c。
.if BuildStealth
    .if BuildNoAuto
        .definelabel Fp2ServiceOffset,      0x0054
        .definelabel Fp2BootStateOffset,    0x006c
        .definelabel Fp2FlashBootOffset,    0x007c
        .definelabel Fp2AuxOffset,          0x00d4
        .definelabel Fp2SpiSetupOffset,     0x017c
        .definelabel Fp2ClearDmaOffset,     0x01bc
        .definelabel Fp2HeaderCopyOffset,   0x01d8
        .definelabel Fp2CopyOffset,         0x0210
        .definelabel Fp2BootReturnOffset,   0x0220
        .definelabel Fp2PoolOffset,         0x022c
    .else
        .definelabel Fp2ServiceOffset,      0x0064
        .definelabel Fp2BootStateOffset,    0x007c
        .definelabel Fp2FlashBootOffset,    0x008c
        .definelabel Fp2AuxOffset,          0x00e4
        .definelabel Fp2SpiSetupOffset,     0x018c
        .definelabel Fp2ClearDmaOffset,     0x01cc
        .definelabel Fp2HeaderCopyOffset,   0x01e8
        .definelabel Fp2CopyOffset,         0x0220
        .definelabel Fp2BootReturnOffset,   0x0230
        .definelabel Fp2PoolOffset,         0x023c
    .endif
.else
    .if BuildNoAuto
        .definelabel Fp2ServiceOffset,      0x0054
        .definelabel Fp2BootStateOffset,    0x00d0
        .definelabel Fp2FlashBootOffset,    0x00e0
        .definelabel Fp2AuxOffset,          0x0138
        .definelabel Fp2SpiSetupOffset,     0x01e0
        .definelabel Fp2ClearDmaOffset,     0x0220
        .definelabel Fp2HeaderCopyOffset,   0x023c
        .definelabel Fp2CopyOffset,         0x0274
        .definelabel Fp2BootReturnOffset,   0x0284
        .definelabel Fp2PoolOffset,         0x0290
    .else
        .definelabel Fp2ServiceOffset,      0x0064
        .definelabel Fp2BootStateOffset,    0x00e0
        .definelabel Fp2FlashBootOffset,    0x00f0
        .definelabel Fp2AuxOffset,          0x0148
        .definelabel Fp2SpiSetupOffset,     0x01f0
        .definelabel Fp2ClearDmaOffset,     0x0230
        .definelabel Fp2HeaderCopyOffset,   0x024c
        .definelabel Fp2CopyOffset,         0x0284
        .definelabel Fp2BootReturnOffset,   0x0294
        .definelabel Fp2PoolOffset,         0x02a0
    .endif
.endif

.definelabel RetailP1Patch0Offset,          0x02dc
.definelabel RetailP1Patch1Offset,          0x089e
.definelabel RetailP1Patch2Offset,          0x08ba
.definelabel RetailP1Patch3Offset,          0x08ce
.definelabel RetailP1Callback0Offset,       0x6de6
.definelabel RetailP1Callback1Offset,       0x6e3c
