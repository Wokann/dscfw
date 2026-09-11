// Primary FlashMe descriptor based on the official V6 header.
// 一级 FlashMe 描述符，以官方 V6 头为基础。
.create "build/h.bin", 0
    .incbin "temp/h.bin"
    .orga HeaderShiftAmountsOffset
    .dh EffectiveShiftAmounts
    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(PrimaryP1RamAddress)
    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(PrimaryP2RamAddress)
    .orga HeaderTypeOffset
    .dh PrimaryTypeId
    // Preserve the original retail P1/P2 CRC16 as FlashMe's source marker.
    // 保留原始零售 P1/P2 CRC16 作为 FlashMe 的来源标记。
    .orga HeaderOriginalVersionOffset
    .incbin "temp/h.bin", HeaderPart12Crc16Offset, 2
.close
