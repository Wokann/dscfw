// Stage 0 primary descriptor.  The normal firmware loader reads H first and
// starts the small P1/P2 pair which forms the first ARM9/ARM7 handshake.  H is
// metadata for that pair; it is not itself executable code.  See main.s.
// 第零阶段的一级描述符。正常固件加载器会先读取 H，并启动构成第一次 ARM9/ARM7 握手的
// 小型 P1/P2 对。H 是该程序对的元数据，本身并不是可执行代码。请参阅 main.s。
.create "build/h.bin", 0
    .incbin "temp/h.bin"
    .if ShiftAmountsOverride >= 0
        // English: Replace the retail shift_amounts only for an intentional
        // format port.  This field controls how both ROM and RAM descriptor
        // units are interpreted; the default path preserves the retail value.
        // 中文：仅在有意迁移格式时替换零售 shift_amounts。该字段决定 ROM 与
        // RAM 描述符的单位解释；默认路径会保留零售固件原有的数值。
        .orga HeaderShiftAmountsOffset
        .dh EffectiveShiftAmounts
    .endif

    // English: H now names the small replacement primary P1 bootstrap rather
    // than the retail P1 body.  This only changes its encoded RAM descriptor;
    // dsfwtool later derives ROM placement and recalculates component CRCs.
    // 中文：H 现在指向小型替换一级 P1 引导代码，而非零售 P1 主体。此处仅修改
    // 其编码后的 RAM 描述符；ROM 放置及组件 CRC 会由 dsfwtool 后续重新计算。
    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(PrimaryP1RamAddress)

    // English: H likewise names the replacement primary P2 bootstrap.  It is
    // deliberately separate from the later FP2 image that contains retail P2.
    // 中文：H 同样改为指向替换后的一级 P2 引导代码。它刻意与包含零售 P2 的后续
    // FP2 镜像分开。
    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(PrimaryP2RamAddress)

    // English: Set the FlashMe primary-header type marker.  This is a
    // FlashMe-owned tail field, not an official component CRC or ROM address.
    // 中文：设置 FlashMe 一级头类型标记。这是 FlashMe 自有的头尾字段，并非官方
    // 组件 CRC 或 ROM 地址。
    .orga HeaderTypeOffset
    .dh PrimaryTypeId

    // English: The known V1/V3 Phat headers deliberately leave the Wi-Fi
    // configuration checksum as FFFF.  Retain that historical header value
    // instead of carrying the retail V3 checksum into the FlashMe header.
    // 中文：已知 V1/V3 Phat 头会刻意把 Wi-Fi 配置校验保留为 FFFF。此处保留该历史
    // 头部值，而不是把零售 V3 的校验带入 FlashMe 头。
    .orga HeaderWifiConfigCrc16Offset
    .dh 0xffff

    // English: +0x17E remains untouched after the initial source-header copy.
    // Known V1/V3 Phat templates contain FFFF here; this field is not a copy of
    // H +0x006 and is not recomputed by the patch.
    // 中文：初始复制源头后，+0x17E 保持不改。已知 V1/V3 Phat 模板此处为 FFFF；
    // 它不是 H +0x006 的副本，也不会由补丁重算。
.close
