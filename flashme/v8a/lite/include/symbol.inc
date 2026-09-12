; FlashMe build configuration
.definelabel ShiftAmountsOverride,                    0x0c71
.definelabel EffectiveShiftAmounts,                   ShiftAmountsOverride < 0 ? SourceShiftAmounts : ShiftAmountsOverride
.expfunc Part1RamaddrFromRam(address),        (FirmwarePart1RamaddrEncodingBase - (address)) >> (2 + ((EffectiveShiftAmounts >> 3) & 7))
.expfunc Part2RamaddrFromRam(address),        (FirmwarePart2RamaddrEncodingBase - (address)) >> (2 + ((EffectiveShiftAmounts >> 9) & 7))

; FlashMe primary and secondary runtime placement
.definelabel FlashMePrefixBytes,                      0x00000400
.definelabel PrimaryP1StagingRegionEnd,               (RetailP1RamAddress & 0xffe00000)
.definelabel PrimaryP1RamAddress,                     PrimaryP1StagingRegionEnd - 0x00010000
.definelabel PrimaryP2RamAddress,                     FirmwarePart2RamaddrEncodingBase - 0x00000800
.definelabel FlashMeFp1RamAddress,                    RetailP1RamAddress - FlashMePrefixBytes
.definelabel FlashMeFp2RamAddress,                    RetailP2RamAddress - FlashMePrefixBytes

.if FlashMeFp1RamAddress < PrimaryP1StagingRegionEnd
    .error "FlashMe: FP1 prefix overlaps the dynamic primary P1 staging page"
.endif

; FlashMe installer-identification and local handoff fields
.definelabel HeaderTypeOffset,                        0x017c
.definelabel HeaderOriginalVersionOffset,             0x017e
.definelabel PrimaryHeaderInstallerClass,             0x0002
.definelabel SecondaryHeaderInstallerCode,            0x0005
.definelabel FlashMeSecondaryHeaderAddress,           0x0003f680
; FlashMe-only RAM work slots
.definelabel FlashMeArm9FallbackReturnPointerAddress, 0x02100024
.definelabel FlashMeArm9ReturnTrampolineAddress,      NdsCartHeaderDocumentedEndAddress
.definelabel Arm9PowerControlValue,                   0x0000820f
