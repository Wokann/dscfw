// Stage 0 secondary descriptor.  Primary P2 reads this FH after H's P1/P2 pair
// has started; FH then describes the second FP1/FP2 pair.  It is derived from
// the same retail H, but its P1/P2 fields deliberately name the FP components.
// 第零阶段的二级描述符。H 的 P1/P2 对启动后，一级 P2 会读取这个 FH；FH 随后描述
// 第二个 FP1/FP2 程序对。它同样基于零售 H，但其中的 P1/P2 字段会特意指向 FP 组件。
.create "build/fh.bin", 0
    .incbin "temp/h.bin"

    // English: Reconstruct the released FlashMe template rather than an
    // installation for one console.  Blank the copied Wi-Fi calibration and
    // configuration region at +0x28..+0x17B.
    // 中文：重建公开发布的 FlashMe 模板，而非某一台主机的安装结果。将复制来的
    // Wi-Fi 校准与配置区域 +0x28..+0x17B 填充为 FF。
    .orga 0x0028
    .fill 0x0154, 0xff
    .if ShiftAmountsOverride >= 0
        // English: Keep FH's unit encoding synchronized with H when a format
        // port explicitly overrides shift_amounts; otherwise retain retail H.
        // 中文：当格式迁移显式覆写 shift_amounts 时，使 FH 的单位编码与 H 同步；
        // 否则保留零售 H 的原值。
        .orga HeaderShiftAmountsOffset
        .dh EffectiveShiftAmounts
    .endif

    // English: FH describes FP1, whose 0x400-byte prefix precedes retail P1.
    // The encoded descriptor makes the retail P1 body still begin at its
    // original RAM address after that prefix.
    // 中文：FH 描述 FP1；FP1 的 0x400 字节前置代码位于零售 P1 之前。该编码描述符
    // 会使零售 P1 主体在前置代码之后仍从它原本的 RAM 地址开始。
    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(FlashMeFp1RamAddress)

    // English: FH likewise describes FP2, with its prefix immediately before
    // retail P2.  It is a secondary-header descriptor, not H's primary P2.
    // 中文：FH 同样描述 FP2，其前置代码紧邻零售 P2 之前。这是二级头描述符，并非
    // H 的一级 P2 描述符。
    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(FlashMeFp2RamAddress)

    // English: Set FH's independent FlashMe type marker.  dsfwtool later
    // synchronizes the shared H/FH fields but deliberately keeps this marker.
    // 中文：设置 FH 独立的 FlashMe 类型标记。dsfwtool 后续会同步 H/FH 的共有字段，
    // 但会刻意保留该标记。
    .orga HeaderTypeOffset
    .dh FlashMeTypeId

    // English: The public release template fixes the source/private marker at
    // +0x17E to FFFF.  Do not import a retail P1/P2 CRC16 into this field.
    // 中文：公开发布模板会将 +0x17E 的来源/私有标记固定为 FFFF；不得把零售
    // P1/P2 CRC16 导入该字段。
    .orga HeaderOriginalVersionOffset
    .dh 0xffff
.close
