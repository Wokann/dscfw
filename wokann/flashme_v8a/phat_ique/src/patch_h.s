
.create "build/h.bin", 0
    .incbin "temp/h.bin"

    .orga 0x0028
    .fill 0x0154, 0xff
    .if ShiftAmountsOverride >= 0
        .orga HeaderShiftAmountsOffset
        .dh EffectiveShiftAmounts
    .endif
    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(PrimaryP1RamAddress)
    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(PrimaryP2RamAddress)

    .orga HeaderTypeOffset
    .dh PrimaryHeaderInstallerClass

    .orga HeaderOriginalVersionOffset
    .dh 0xffff
.close
