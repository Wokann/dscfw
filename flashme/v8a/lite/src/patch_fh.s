// Secondary descriptor.  dsfwtool synchronizes final shared H fields here,
// retaining the FP1/FP2 descriptors and this FlashMe-specific type marker.
// 二级描述符。dsfwtool 会同步完成后的 H 共有字段，同时保留 FP1/FP2 描述符及
// 此 FlashMe 专用类型标记。
.create "build/fh.bin", 0
    .incbin "temp/h.bin"

    // English: Reconstruct the released FlashMe template rather than an
    // installation for one console.  Blank the copied Wi-Fi calibration and
    // configuration region at +0x28..+0x17B.
    // 中文：重建公开发布的 FlashMe 模板，而非某一台主机的安装结果。将复制来的
    // Wi-Fi 校准与配置区域 +0x28..+0x17B 填充为 FF。
    .orga 0x0028
    .fill 0x0154, 0xff
    .orga HeaderShiftAmountsOffset
    .dh EffectiveShiftAmounts
    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(FlashMeFp1RamAddress)
    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(FlashMeFp2RamAddress)
    // English: Preserve the published FlashMe secondary type marker at +0x17C.
    // 中文：保留公开 FlashMe 模板在 +0x17C 使用的二级类型标记。
    .orga HeaderTypeOffset
    .dh FlashMeTypeId

    // English: The public release template fixes the source/private marker at
    // +0x17E to FFFF.  Do not import a retail P1/P2 CRC16 into this field.
    // 中文：公开发布模板会将 +0x17E 的来源/私有标记固定为 FFFF；不得把零售
    // P1/P2 CRC16 导入该字段。
    .orga HeaderOriginalVersionOffset
    .dh 0xffff
.close
