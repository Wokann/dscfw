
.create "build/fh.bin", 0
    .incbin "temp/h.bin"

    .orga 0x0028
    .fill 0x0154, 0xff
    .orga HeaderShiftAmountsOffset
    .dh EffectiveShiftAmounts
    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(FlashMeFp1RamAddress)
    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(FlashMeFp2RamAddress)

    .orga HeaderTypeOffset
    .dh SecondaryHeaderInstallerCode

    .orga HeaderOriginalVersionOffset
    .dh 0xffff
.close
