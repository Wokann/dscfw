; NDS hardware registers and input
.definelabel REG_DMA0SAD,                             0x040000b0
.definelabel REG_KEYINPUT,                            0x04000130
.definelabel REG_KEYXY,                               0x04000136
.definelabel REG_IPC_SYNC,                            0x04000180
.definelabel REG_AUXSPICNT,                           0x040001a0
.definelabel REG_ROMCTRL,                             0x040001a4
.definelabel REG_SPICNT,                              0x040001c0
.definelabel REG_SPIDATA,                             0x040001c2
.definelabel VRAM_A_CR,                               0x04000240
.definelabel REG_POWERCNT,                            0x04000304
.definelabel REG_GCDATAIN,                            0x04100010
.definelabel KEY_A,                                   (1 << 0)
.definelabel KEY_B,                                   (1 << 1)
.definelabel KEY_SELECT,                              (1 << 2)
.definelabel KEYXY_X,                                 (1 << 0)
.definelabel KEYXY_Y,                                 (1 << 1)

; NDS memory and video layout
.definelabel BG_PALETTE,                              0x05000000
.definelabel VRAM_A,                                  0x06800000
.definelabel OAM,                                     0x07000000
.definelabel VramLcdcBytes,                           0x000a4000
.definelabel MM_PALRAM_SZ,                            0x00000800
.definelabel MM_OBJRAM_SZ,                            0x00000800
.definelabel WRAM_0KARM9_32KARM7,                     0x03
.definelabel VramcntLcdcEnableAbcd,                   0x80808080

; BIOS service and fixed boot entry points
.definelabel SwiCustomPost,                           0x001f0000
.definelabel SwiWaitByLoop,                           0x00030000
.definelabel SwiSoundBias,                            0x00080000
.definelabel SwiCpuFastSet,                           0x000c0000
.definelabel Bios7SignalBootFinish,                   0x0000119d
.definelabel Bios7PowerManagementWrite,               0x00002369
.definelabel Bios7FirmwareRead,                       0x00002437
.definelabel Bios7Lz77UncompVram,                     0x00002a2b
.definelabel Bios7CpuFastSetArm,                      0x000030e4
.definelabel Bios7SpiTransferFinish,                  0x000022c7
.definelabel Bios7FirmwareReadBegin,                  0x00002389
.definelabel Bios7SpiTransferBuffer,                  0x000033a5
.definelabel Bios9NintendoLogoAddress,                0xffff0020

; Standard firmware header data shared by every reconstruction.
.definelabel HeaderPart1RamaddrOffset,                0x000e
.definelabel HeaderPart2RamaddrOffset,                0x0012
.definelabel HeaderShiftAmountsOffset,                0x0014
.definelabel FirmwarePart1RamaddrEncodingBase,        0x02800000
.definelabel FirmwarePart2RamaddrEncodingBase,        0x03810000
.definelabel SourceShiftAmounts,                       readu16("temp/h.bin", HeaderShiftAmountsOffset)

; Firmware user-settings storage and its retail RAM mirror
.definelabel FirmwareUserSettingsAddress256K,         0x0003fe00
.definelabel FirmwareUserSettingsAddress512K,         0x0007fe00
.definelabel FirmwareUserSettingsRamAddress,          0x023ffc80

; NDS card header copied to ARM9 RAM; 0x023Fxxxx is the retail 4 MiB mirror.
; GBATEK documents populated header fields through +0x16F.  The following
; address at +0x170 is documented as unused and zero-filled at cartridge boot;
; FlashMe uses that otherwise free location for its own return trampoline.
.definelabel NdsCartHeaderRamAddress,                 0x027ffe00
.definelabel NdsCartHeaderRetailMirrorAddress,        0x023ffe00
.definelabel NdsCartHeaderDocumentedBytes,            0x00000170
.definelabel NdsCartHeaderDocumentedEndAddress,       NdsCartHeaderRamAddress + NdsCartHeaderDocumentedBytes
.definelabel NdsCartHeaderArm9EntryAddress,           NdsCartHeaderRamAddress + 0x24
.definelabel NdsCartHeaderArm9RamAddress,             NdsCartHeaderRamAddress + 0x28
.definelabel NdsCartHeaderArm7EntryAddress,           NdsCartHeaderRamAddress + 0x34
.definelabel NdsCartHeaderRetailArm9EntryAddress,     NdsCartHeaderRetailMirrorAddress + 0x24
.definelabel NdsCartHeaderRetailArm9RamAddress,       NdsCartHeaderRetailMirrorAddress + 0x28

; Slot-2 header locations
.definelabel GbaRomTitleAddress,                      0x080000a0
.definelabel GbaArm7Entry,                            0x080000c0
