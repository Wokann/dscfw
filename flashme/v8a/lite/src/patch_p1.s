// FlashMe V8a Lite primary ARM9 bootstrap.
//
// The official V8a Lite variants use this same plaintext P1.  It is stored in
// the Lite package itself so this reconstruction has no source dependency on
// the Phat package.
//
// 所有官方 V8a Lite 变体均使用同一份明文 P1。它直接存于 Lite 包中，
// 因此本重建工程不会在源码层面依赖 Phat 包。
.create "build/p1.bin", 0
    .headersize PrimaryP1RamAddress
    .area PrimaryP1Bytes, 0x00
    .arm

    // The word at +0x04 is the ARM7-to-ARM9 command slot.  Zero parks P1,
    // one requests cold preparation, and another value is an ARM9 continuation.
    // +0x04 的字是 ARM7 到 ARM9 的命令槽：零表示停驻，1 表示冷启动准备，
    // 其余值则是 ARM9 续接地址。
    b p1_wait_command
p1_command:
    .dw 0x00000000

p1_wait_command:
    ldr r0, [pc, #-0x0c]
    cmp r0, #0
    beq p1_wait_command
    cmp r0, #1
    beq p1_cold_boot
    bx r0

p1_cold_boot:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, =REG_DMA0SAD

p1_clear_dma:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl p1_clear_dma

    mov r0, #1
    swi 0x1f0000
    ldr r1, =REG_POWERCNT
    mov r0, #0
    strh r0, [r1]

    // Map all VRAM to LCDC, erase it, then hand shared WRAM to ARM7.
    // 将全部 VRAM 映射到 LCDC、清零，然后把共享 WRAM 交给 ARM7。
    ldr r4, =VRAM_A_CR
    ldr r5, =VramLcdcDisableAll
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    // Preserve official V8a instruction encodings.
    // 保留官方 V8a 的指令编码。
    .dw 0xe3a01668 // mov r1, #0x06800000
    .dw 0xe3a02aa4 // mov r2, #0x000a4000
    bl p1_zero_halfwords
    .dw 0xe3a057c0 // mov r5, #0x03000000
    strh r5, [r4]
    strh r5, [r4, #2]
    str r5, [r4, #4]
    strh r5, [r4, #8]

    ldr r0, =REG_POWERCNT
    ldr r1, =Arm9BootState
    strh r1, [r0]
    .dw 0xe3a01670 // mov r1, #OAM
    .dw 0xe3a02e80 // mov r2, #MM_OBJRAM_SZ
    bl p1_zero_halfwords
    .dw 0xe3a01650 // mov r1, #BG_PALETTE
    .dw 0xe3a02e80 // mov r2, #MM_PALRAM_SZ
    bl p1_zero_halfwords

    // Clear two observed system-control words before another command cycle.
    // 清除两个观察到的系统控制字，再进入下一轮命令循环。
    .dw 0xe3a00640 // mov r0, #0x04000000
    mov r1, #0
    str r1, [r0]
    .dw 0xe2800d40 // add r0, r0, #0x00001000
    str r1, [r0]
    mov r0, #0
    str r0, [pc, #-0x0c4]
    b p1_wait_command

p1_zero_halfwords:
    mov r0, #0
p1_zero_loop:
    strh r0, [r1], #2
    strh r0, [r1], #2
    strh r0, [r1], #2
    strh r0, [r1], #2
    subs r2, r2, #8
    bne p1_zero_loop
    mov pc, lr

    .orga PrimaryP1PoolOffset
    .pool
    .endarea
.close

// =============================================================================
// C flow model (English)
// =============================================================================
//
// static void PrimaryP1V8a(void)
// {
//     for (;;) {
//         const uintptr_t command = *(volatile uintptr_t *)(PrimaryP1Ram + 4);
//         if (command == 0)
//             continue;
//         if (command != 1)
//             ((void (*)(void))command)();
//         ClearDmaChannels();
//         ResetArm9VisibleVideoAndMemory();
//         *(volatile uintptr_t *)(PrimaryP1Ram + 4) = 0;
//     }
// }
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
//
// P1 在命令字为零时等待。P2 写入 1 时，P1 清理 ARM9 可见的 DMA、显示和内存状态，
// 再把命令清零；写入其他地址时，它直接跳转至该 ARM9 续接地址。因此 P2 负责启动
// 决策，P1 只完成被请求的 ARM9 准备。
