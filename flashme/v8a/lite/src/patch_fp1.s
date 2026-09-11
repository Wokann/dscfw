// FlashMe V8a Lite second-stage ARM9 prefix.
//
// This local Lite copy precedes retained official V6 P1.  Its 0x400-byte prefix
// ends exactly at the V6 retail entry address decoded from temp/h.bin.
//
// 本地 Lite 副本位于保留的官方 V6 P1 之前。其 0x400 字节前置区恰好在从 temp/h.bin
// 解码出的 V6 零售入口处结束。
.create "build/fp1.bin", 0
    .headersize FlashMeFp1RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    ldr r10, [fp1_context_ipc_sync]

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    cmp r0, #0x0b
    bcc fp1_wait_b
    beq fp1_warm_boot
    cmp r0, #0x0c
    beq fp1_cold_boot
    bl fp1_cold_prepare
    ldr lr, [fp1_slot_arm9_unknown_return]
    ldr lr, [lr]
    bx lr

fp1_warm_boot:
    .if BuildStealth
        // Stealth resumes retained ARM9 immediately after phase B.
        // Stealth 在 B 阶段后立即恢复保留 ARM9。
        ldr lr, [fp1_slot_arm9_return]
        ldr lr, [lr]
        b fp1_retail
    .else
        // Normal and NoAuto wait for FP2 to publish phase E.
        // 常规版与 NoAuto 会等待 FP2 发布 E 阶段。
        ldr r0, [fp1_slot_powercnt]
        ldr r1, [fp1_slot_arm9_boot_state]
        strh r1, [r0]

fp1_wait_e_warm:
        ldrh r0, [r10]
        and r0, r0, #0x0f
        cmp r0, #0x0e
        bne fp1_wait_e_warm
        ldr lr, [fp1_slot_arm9_return]
        ldr lr, [lr]
        b fp1_retail
    .endif

    .if BuildStealth
        .orga 0x03c
    .else
        .orga 0x058
    .endif
fp1_cold_boot:
    bl fp1_cold_prepare
    adr r12, fp1_context
    ldmia r12, {r4-r9}
    stmia r4, {r5,r6}
    str r4, [r9]
    bx r4

    .orga Fp1ContextOffset
fp1_context:
fp1_context_r4:
    .dw Arm9ReturnTrampolineAddress

    .headersize Arm9ReturnTrampolineAddress - orga(fp1_context_r4)
    .orga orga(fp1_context_r4)
fp1_runtime_trampoline_entry:
    .orga orga(fp1_context_r4) + 4
fp1_context_r5:
    mov r0, r0
fp1_context_r6:
    ldr pc, [r9]
    .headersize FlashMeFp1RamAddress
fp1_context_ipc_sync:
    .dw REG_IPC_SYNC
fp1_context_ipc_phase_e:
    .dw 0x00000e00
fp1_context_arm9_return:
    .dw Arm9ReturnSlot

    .orga Fp1ColdPrepareOffset
fp1_cold_prepare:
    mov r11, lr
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp1_slot_dma0_sad]

fp1_clear_dma:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_dma

    mov r0, #1
    swi 0x1f0000
    ldr r1, [fp1_slot_powercnt]
    mov r0, #0
    strh r0, [r1]

    // Map LCDC VRAM, clear it, and assign shared WRAM to ARM7.
    // 映射 LCDC VRAM、清零，并将共享 WRAM 分配给 ARM7。
    ldr r4, [fp1_slot_vram_a_cr]
    ldr r5, [fp1_slot_vram_lcdc_disable_all]
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    mov r1, #VRAM_A
    mov r2, #VramLcdcBytes
    bl fp1_zero_range
    mov r5, #(WRAM_0KARM9_32KARM7 << 24)
    strh r5, [r4]
    strh r5, [r4, #2]
    str r5, [r4, #4]
    strh r5, [r4, #8]

    mov r3, #FirmwarePart1RamaddrBase
    ldrb r0, [r3, #-4]
    cmp r0, #0
    beq fp1_wait_e_cold
    sub r1, r3, #0x200
    mov r2, #0x170
    bl fp1_zero_range
    ldr r0, [fp1_slot_clear_source]
    sub r1, r3, #0x140
    mov r2, #0x28
    swi SwiArm7CpuFastSetImmediate

fp1_wait_e_cold:
    ldr r0, [fp1_slot_powercnt]
    ldr r1, [fp1_slot_arm9_boot_state]
    strh r1, [r0]
    mov r1, #OAM
    mov r2, #MM_OBJRAM_SZ
    bl fp1_zero_range
    mov r1, #BG_PALETTE
    mov r2, #MM_PALRAM_SZ
    bl fp1_zero_range

    // V8a clears two extra system-control words before phase E.
    // V8a 会在 E 阶段前额外清除两个系统控制字。
    mov r0, #0x04000000
    mov r1, #0
    str r1, [r0]
    add r0, r0, #0x1000
    str r1, [r0]
    mov r0, #0x0e00
    strh r0, [r10]
    bx r11

fp1_zero_range:
    mov r0, #0
fp1_zero_loop:
    strh r0, [r1], #2
    strh r0, [r1], #2
    strh r0, [r1], #2
    strh r0, [r1], #2
    subs r2, r2, #8
    bne fp1_zero_loop
    mov pc, lr

    .orga Fp1PoolOffset
    .if BuildStealth
fp1_slot_arm9_unknown_return:
    .dw Arm9UnknownReturnSlot
fp1_slot_arm9_return:
    .dw Arm9ReturnSlot
fp1_slot_dma0_sad:
    .dw REG_DMA0SAD
fp1_slot_powercnt:
    .dw REG_POWERCNT
fp1_slot_vram_a_cr:
    .dw VRAM_A_CR
fp1_slot_vram_lcdc_disable_all:
    .dw VramLcdcDisableAll
fp1_slot_clear_source:
    .dw Fp1ClearSourceAddress
fp1_slot_arm9_boot_state:
    .dw Arm9BootState
    .else
fp1_slot_arm9_unknown_return:
    .dw Arm9UnknownReturnSlot
fp1_slot_powercnt:
    .dw REG_POWERCNT
fp1_slot_arm9_boot_state:
    .dw Arm9BootState
fp1_slot_arm9_return:
    .dw Arm9ReturnSlot
fp1_slot_dma0_sad:
    .dw REG_DMA0SAD
fp1_slot_vram_a_cr:
    .dw VRAM_A_CR
fp1_slot_vram_lcdc_disable_all:
    .dw VramLcdcDisableAll
fp1_slot_clear_source:
    .dw Fp1ClearSourceAddress
    .endif
    .endarea

fp1_retail:
    .incbin "temp/p1.bin"

    .if !BuildStealth
        // Normal and NoAuto alter four Lite retail P1 checks.
        // 常规版与 NoAuto 会修改四处 Lite 零售 P1 检查。
        .orga FlashMePrefixBytes + RetailP1Patch0Offset
        .thumb
        lsl r3, r4, #0

        .orga FlashMePrefixBytes + RetailP1Patch1Offset
        .thumb
        cmp r1, #1

        .orga FlashMePrefixBytes + RetailP1Patch2Offset
        .thumb
        cmp r0, #1

        .orga FlashMePrefixBytes + RetailP1Patch3Offset
        .thumb
        lsl r0, r0, #0
    .endif

    // Both normal and Stealth retain these two callback bypasses.
    // 常规版与 Stealth 均保留这两处回调绕过。
    .orga FlashMePrefixBytes + RetailP1Callback0Offset
    .thumb
    .dh 0x0000

    .orga FlashMePrefixBytes + RetailP1Callback1Offset
    .thumb
    .dh 0x0000
.close

// =============================================================================
// C flow model (English)
// =============================================================================
//
// FP1 consumes FP2's B/C/E IPC phase.  B returns to retained ARM9 (after an E
// wait except in Stealth); C clears ARM9-visible state and installs the return
// trampoline; E completes the cross-CPU rendezvous.  Its prefix remains 0x400
// bytes, so retained V6 P1 enters at its native address.
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
//
// FP1 消费 FP2 发布的 B/C/E IPC 阶段。B 恢复保留 ARM9（Stealth 以外会先等待 E）；
// C 清理 ARM9 可见状态并安装返回跳板；E 完成跨 CPU 会合。前置区固定为 0x400 字节，
// 因而保留的 V6 P1 仍从原生地址进入。
