// FlashMe V8a Phat second-stage ARM9 prefix.
//
// This V8a Phat FP1 prefix precedes the retained retail V3 P1 body.  It stays
// in the Phat package even where Lite has equivalent bytes, keeping the two
// reconstruction projects independently portable.
//
// 这份 V8a Phat FP1 前置代码位于保留的零售 V3 P1 主体之前。即使 Lite 存在等价字节，
// 它仍保留在 Phat 包内，从而使两套重建工程可以独立移植。
.create "build/fp1.bin", 0
    .headersize FlashMeFp1RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    ldr r10, [pc, #Fp1ContextOffset + 4]

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    cmp r0, #0x0b
    bcc fp1_wait_b
    beq fp1_warm_boot
    cmp r0, #0x0c
    beq fp1_cold_boot
    bl fp1_cold_prepare
    ldr lr, =Arm9UnknownReturnSlot
    ldr lr, [lr]
    bx lr

fp1_warm_boot:
    .if BuildStealth
        // In Stealth, phase B resumes retained ARM9 immediately.
        // Stealth 中，B 阶段会立即恢复保留的 ARM9。
        ldr lr, =Arm9ReturnSlot
        ldr lr, [lr]
        b fp1_retail
    .else
        // Normal and NoAuto wait for FP2 to publish phase E.
        // 常规版与 NoAuto 会等待 FP2 发布 E 阶段。
        ldr r0, =REG_POWERCNT
        ldr r1, =Arm9BootState
        strh r1, [r0]

fp1_wait_e_warm:
        ldrh r0, [r10]
        and r0, r0, #0x0f
        cmp r0, #0x0e
        bne fp1_wait_e_warm
        ldr lr, =Arm9ReturnSlot
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
    .dw Arm9ReturnTrampolineAddress
    .dw 0xe1a00000
    .dw 0xe599f000
    .dw REG_IPC_SYNC
    .dw 0x00000e00
    .dw Arm9ReturnSlot

    .orga Fp1ColdPrepareOffset
fp1_cold_prepare:
    mov r11, lr
    mov r0, #0
    mov r2, #0x2c
    ldr r1, =REG_DMA0SAD

fp1_clear_dma:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_dma

    mov r0, #1
    swi 0x1f0000
    ldr r1, =REG_POWERCNT
    mov r0, #0
    strh r0, [r1]

    // Map LCDC VRAM, clear it, and assign shared WRAM to ARM7.
    // 映射 LCDC VRAM、清零，并将共享 WRAM 分配给 ARM7。
    ldr r4, =VRAM_A_CR
    ldr r5, =VramLcdcDisableAll
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    .dw 0xe3a01668 // mov r1, #0x06800000
    .dw 0xe3a02aa4 // mov r2, #0x000a4000
    bl fp1_zero_range
    .dw 0xe3a057c0 // mov r5, #0x03000000
    strh r5, [r4]
    strh r5, [r4, #2]
    str r5, [r4, #4]
    strh r5, [r4, #8]

    .dw 0xe3a037a0 // mov r3, #0x02800000
    ldrb r0, [r3, #-4]
    cmp r0, #0
    beq fp1_wait_e_cold
    .dw 0xe2431f80 // sub r1, r3, #0x200
    .dw 0xe3a02f5c // mov r2, #0x170
    bl fp1_zero_range
    ldr r0, =Fp1ClearSourceAddress
    .dw 0xe2431f50 // sub r1, r3, #0x140
    mov r2, #0x28
    swi SwiArm7CpuFastSetImmediate

fp1_wait_e_cold:
    ldr r0, =REG_POWERCNT
    ldr r1, =Arm9BootState
    strh r1, [r0]
    .dw 0xe3a01670 // mov r1, #OAM
    .dw 0xe3a02e80 // mov r2, #MM_OBJRAM_SZ
    bl fp1_zero_range
    .dw 0xe3a01650 // mov r1, #BG_PALETTE
    .dw 0xe3a02e80 // mov r2, #MM_PALRAM_SZ
    bl fp1_zero_range

    // V8a additionally clears two system-control words before phase E.
    // V8a 还会在发布 E 阶段之前额外清除两个系统控制字。
    .dw 0xe3a00640 // mov r0, #0x04000000
    mov r1, #0
    str r1, [r0]
    .dw 0xe2800d40 // add r0, r0, #0x00001000
    str r1, [r0]
    .dw 0xe3a00ee0 // mov r0, #0x0e00
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
    .pool
    .endarea

fp1_retail:
    .incbin "temp/p1.bin"

    .if !BuildStealth
        // Normal and NoAuto modify four retail checks; Stealth leaves them.
        // 常规版与 NoAuto 会修改四处零售检查；Stealth 保持原样。
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

    // These two callback bypasses apply to both normal and Stealth layouts.
    // 这两处回调绕过同时适用于常规与 Stealth 布局。
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
// FP1 consumes the B/C/E phase chosen by FP2.  B resumes retail ARM9 (after an
// E wait except in Stealth); C clears ARM9-visible state and installs a compact
// return trampoline; E completes the cross-CPU rendezvous.  The prefix remains
// exactly 0x400 bytes so retained P1 enters at its original retail RAM address.
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
//
// FP1 消费由 FP2 选择的 B/C/E 阶段。B 恢复零售 ARM9（Stealth 以外会先等待 E）；
// C 清理 ARM9 可见状态并安装紧凑的返回跳板；E 完成跨 CPU 会合。前置区固定为 0x400
// 字节，因此保留 P1 仍从原本的零售 RAM 地址进入。
