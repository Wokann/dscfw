
.definelabel REG_KEYINPUT,                  0x04000130
.definelabel REG_KEYXY,                     0x04000136
.definelabel REG_IPC_SYNC,                  0x04000180
.definelabel REG_SPICNT,                    0x040001c0
.definelabel REG_SPIDATA,                   0x040001c2
.definelabel REG_AUXSPICNT,                 0x040001a0
.definelabel REG_DMA0SAD,                   0x040000b0
.definelabel REG_GCDATAIN,                  0x04100010
.definelabel VRAM_A_CR,                     0x04000240
.definelabel WRAM_CR,                       0x04000247
.definelabel REG_POWERCNT,                  0x04000304

.definelabel KEY_A,                         (1 << 0)
.definelabel KEY_B,                         (1 << 1)
.definelabel KEY_SELECT,                    (1 << 2)
.definelabel KEY_X,                         (1 << 10)
.definelabel KEY_Y,                         (1 << 11)
.definelabel KEYXY_X,                       (1 << 0)
.definelabel KEYXY_Y,                       (1 << 1)

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

.definelabel BG_PALETTE,                    0x05000000
.definelabel MM_PALRAM_SZ,                  0x00000800
.definelabel OAM,                           0x07000000
.definelabel MM_OBJRAM_SZ,                  0x00000800
.definelabel GBAROM,                        0x08000000
.definelabel GbaRomTitleAddress,            GBAROM + 0x0a0

.definelabel VRAM_ENABLE,                   (1 << 7)
.definelabel VRAM_A_LCD,                    0x00
.definelabel VRAM_B_LCD,                    0x00
.definelabel VRAM_C_LCD,                    0x00
.definelabel VRAM_D_LCD,                    0x00

.definelabel WRAM_0KARM9_32KARM7,           0x03

.definelabel VramLcdcEnableAbcd,            (VRAM_ENABLE | VRAM_A_LCD) | ((VRAM_ENABLE | VRAM_B_LCD) << 8) | ((VRAM_ENABLE | VRAM_C_LCD) << 16) | ((VRAM_ENABLE | VRAM_D_LCD) << 24)
.definelabel VramLcdcDisableAll,            0x80808080

.definelabel SwiArm7WaitByLoopImmediate,    0x00030000
.definelabel SwiArm7SoundBiasImmediate,     0x00080000
.definelabel SwiArm7CpuFastSetImmediate,    0x000c0000

.definelabel BiosCopyRoutine,               0x00002437
.definelabel BiosIpcSendRoutine,            0x00002369
.definelabel BiosBootReturnRoutine,         0x0000119d
.definelabel PrimaryP2ComputeRoutine,       0x000030e4
.definelabel PrimaryP2SwiRoutine,           0x00002369
.definelabel PrimaryP2LegacyCallRoutine,    0x00002389
.definelabel PrimaryP2LegacyCopyRoutine,    0x000033a5

.definelabel PrimaryP2LegacyCallbackValue,  0x000022c7

.definelabel FirmwareHeaderSize,            0x180
.definelabel HeaderPart12Crc16Offset,       0x006
.definelabel HeaderPart1RamaddrOffset,      0x00e
.definelabel HeaderPart2RamaddrOffset,      0x012
.definelabel HeaderShiftAmountsOffset,      0x014

.definelabel FirmwarePart1RamaddrBase,      0x02800000
.definelabel FirmwarePart2RamaddrBase,      0x03810000

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

.definelabel RetailP3RamAddress,            0x02380000

.definelabel FlashMePrefixBytes,            0x400

.definelabel PrimaryP1StagingPageBytes,     0x00010000
.expfunc Arm9RetailRegionFloor(address),    (address) & 0xffe00000
.definelabel PrimaryP1StagingRegionEnd,     Arm9RetailRegionFloor(RetailP1RamAddress)
.definelabel PrimaryP1RamAddress,           PrimaryP1StagingRegionEnd - PrimaryP1StagingPageBytes

.definelabel PrimaryP1ReleaseSlotOffset,   0x0008

.definelabel PrimaryP2StagingWindowBytes,   0x00000800
.definelabel PrimaryP2RamAddress,           FirmwarePart2RamaddrBase - PrimaryP2StagingWindowBytes

.definelabel FlashMeFp1RamAddress,          RetailP1RamAddress - FlashMePrefixBytes
.definelabel FlashMeFp2RamAddress,          RetailP2RamAddress - FlashMePrefixBytes

.if FlashMeFp1RamAddress < PrimaryP1StagingRegionEnd
    .error "FlashMe: FP1 prefix overlaps the dynamic primary P1 staging page"
.endif

.definelabel HeaderTypeOffset,              0x17c
.definelabel HeaderOriginalVersionOffset,   0x17e
.definelabel PrimaryTypeId,                 0x0002
.definelabel FlashMeTypeId,                 0x0005

.definelabel FlashMeFirmwareBytes,          0x0003fe00

.definelabel FlashMePrimaryHeaderAddress,   0x0003f680
.definelabel FlashMeHeaderRamAddress,       0x023ffc80
.definelabel FlashMeAuxSpiControl,          0x0000a040
.definelabel DmaCardCopyControl,            0xaf000001
.definelabel PhatSpiInitialControl,         0x00008802
.definelabel PhatSpiFollowupControl,        0x00008002
.definelabel Arm9ReturnSlot,                0x027ffe24
.definelabel Arm9ReturnSlotNext,            0x027ffe28
.definelabel Arm9ReturnSlotFp2,             0x027ffe34
.definelabel Arm9UnknownReturnSlot,         0x02100024
.definelabel Arm9BootState,                 0x0000820f
.definelabel Arm7ReturnEntry,               0x080000c0

.if BuildStealth
    .definelabel Fp1ContextOffset,          0x054
    .definelabel Fp1ColdPrepareOffset,      0x06c
    .definelabel Fp1PoolOffset,             0x150
.else
    .definelabel Fp1ContextOffset,          0x070
    .definelabel Fp1ColdPrepareOffset,      0x088
    .definelabel Fp1PoolOffset,             0x16c
.endif

.if BuildStealth
    .if BuildNoAuto
        .definelabel Fp2ServiceOffset,      0x060
        .definelabel Fp2BootStateOffset,    0x078
        .definelabel Fp2FlashBootOffset,    0x088
        .definelabel Fp2AuxOffset,          0x0e0
        .definelabel Fp2SpiSetupOffset,     0x188
        .definelabel Fp2ClearDmaOffset,     0x1c8
        .definelabel Fp2HeaderCopyOffset,   0x1e4
        .definelabel Fp2CopyOffset,         0x21c
        .definelabel Fp2BootReturnOffset,   0x22c
        .definelabel Fp2PoolOffset,         0x238
    .else
        .definelabel Fp2ServiceOffset,      0x064
        .definelabel Fp2BootStateOffset,    0x07c
        .definelabel Fp2FlashBootOffset,    0x08c
        .definelabel Fp2AuxOffset,          0x0e4
        .definelabel Fp2SpiSetupOffset,     0x18c
        .definelabel Fp2ClearDmaOffset,     0x1cc
        .definelabel Fp2HeaderCopyOffset,   0x1e8
        .definelabel Fp2CopyOffset,         0x220
        .definelabel Fp2BootReturnOffset,   0x230
        .definelabel Fp2PoolOffset,         0x23c
    .endif
.else
    .if BuildNoAuto
        .definelabel Fp2ServiceOffset,      0x060
        .definelabel Fp2BootStateOffset,    0x0dc
        .definelabel Fp2FlashBootOffset,    0x0ec
        .definelabel Fp2AuxOffset,          0x144
        .definelabel Fp2SpiSetupOffset,     0x1ec
        .definelabel Fp2ClearDmaOffset,     0x22c
        .definelabel Fp2HeaderCopyOffset,   0x248
        .definelabel Fp2CopyOffset,         0x280
        .definelabel Fp2BootReturnOffset,   0x290
        .definelabel Fp2PoolOffset,         0x29c
    .else
        .definelabel Fp2ServiceOffset,      0x064
        .definelabel Fp2BootStateOffset,    0x0e0
        .definelabel Fp2FlashBootOffset,    0x0f0
        .definelabel Fp2AuxOffset,          0x148
        .definelabel Fp2SpiSetupOffset,     0x1f0
        .definelabel Fp2ClearDmaOffset,     0x230
        .definelabel Fp2HeaderCopyOffset,   0x24c
        .definelabel Fp2CopyOffset,         0x284
        .definelabel Fp2BootReturnOffset,   0x294
        .definelabel Fp2PoolOffset,         0x2a0
    .endif
.endif
.definelabel Arm9ReturnTrampolineAddress,   0x027fff70
.definelabel Fp1ClearSourceAddress,         0xffff0020
