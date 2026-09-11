// Secondary descriptor.  dsfwtool synchronizes final shared H fields here,
// retaining the FP1/FP2 descriptors and this FlashMe-specific type marker.
// 二级描述符。dsfwtool 会同步完成后的 H 共有字段，同时保留 FP1/FP2 描述符及
// 此 FlashMe 专用类型标记。
.create "build/fh.bin", 0
    .incbin "temp/h.bin"
    .orga HeaderShiftAmountsOffset
    .dh EffectiveShiftAmounts
    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(FlashMeFp1RamAddress)
    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(FlashMeFp2RamAddress)
    .orga HeaderTypeOffset
    .dh FlashMeTypeId
    .orga HeaderOriginalVersionOffset
    .incbin "temp/h.bin", HeaderPart12Crc16Offset, 2
.close
