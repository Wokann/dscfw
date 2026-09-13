.create "build/fh.bin", 0
    .incbin "temp/h.bin"

    .orga 0x0028
    .fill 0x0154, 0xff
    .if ShiftAmountsOverride >= 0

        .orga HeaderShiftAmountsOffset
        .dh EffectiveShiftAmounts
    .endif

    .orga HeaderPart1RamaddrOffset
    .dh Part1RamaddrFromRam(FlashMeFp1RamAddress)

    .orga HeaderPart2RamaddrOffset
    .dh Part2RamaddrFromRam(FlashMeFp2RamAddress)

    .orga HeaderTypeOffset
    .dh SecondaryHeaderInstallerCode

    .orga HeaderOriginalVersionOffset
    .dh 0xffff
.close

; Detailed analysis / 详细分析:
; 1. This file emits FH, the FlashMe secondary header, not executable CPU code.
; 2. Its encoded P1/P2 RAM fields are what primary P2 later decodes to find FP1 and FP2.
; 3. V5 packages this header at 0x3F680 instead of 0x3FC80, avoiding the Wi-Fi access-point settings region.
; 1. 本文件输出的是 FlashMe 二级头 FH，而非可执行 CPU 代码。
; 2. 其中编码的 P1/P2 RAM 字段由主 P2 之后解码，用以定位 FP1 与 FP2。
; 3. V5 将该头封包于 0x3F680 而非 0x3FC80，避开 Wi-Fi 接入点设置区。
