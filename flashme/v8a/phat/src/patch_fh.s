// Secondary descriptor.  dsfwtool copies finalized shared H fields here while
// preserving FP1/FP2 descriptors and this FlashMe-specific type marker.
// 二级描述符。dsfwtool 会把完成后的 H 共有字段复制至此，同时保留 FP1/FP2 描述符与
// 此 FlashMe 专用类型标记。
.create "build/fh.bin", 0
    .incbin "temp/h.bin"
    .if ShiftAmountsOverride >= 0
        .orga HeaderShiftAmountsOffset
        .dh EffectiveShiftAmounts
    .endif
    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(FlashMeFp1RamAddress)
    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(FlashMeFp2RamAddress)
    .orga HeaderTypeOffset
    .dh FlashMeTypeId
    .orga HeaderOriginalVersionOffset
    .incbin "temp/h.bin", HeaderPart12Crc16Offset, 2
.close
