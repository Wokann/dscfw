.create "build/p1.bin", 0
    .headersize PrimaryP1RamAddress
    .arm
    str r0, [r12, r0, lsl #3]

; Load the staged primary-P1 continuation and branch; P2 has already made the boot choice. See after .close.
; 读取已暂存的主 P1 后续代码并跳转；启动选择已由 P2 完成。详见 .close 后。
    ldr r0, [p1_handoff_slot]
    bx r0
p1_handoff_slot:
    .dw PrimaryP1RamAddress + 4

    .dw 0x00000000
p1_primary_end:

    .if p1_primary_end > PrimaryP1StagingRegionEnd
        .error "FlashMe: primary P1 exceeds its staging page"
    .endif
.close

; Detailed analysis / 详细分析:
; 1. P1 is entered after the boot ROM has staged the primary ARM9 code.
; 2. The stub loads the continuation address from `p1_handoff_slot` (`PrimaryP1RamAddress + 4`).
; 3. `bx r0` resumes that original/staged P1 flow; this P1 stub neither reads a cartridge nor chooses a boot source.
; 1. P1 在 Boot ROM 暂存主 ARM9 代码后进入。
; 2. 桩从 `p1_handoff_slot`（`PrimaryP1RamAddress + 4`）取出后续地址。
; 3. `bx r0` 恢复原始/暂存的 P1 流程；该 P1 桩既不读卡，也不选择启动源。
