// FlashMe V8a Phat primary ARM9 bootstrap.
//
// The official V8a Phat variants use this same plaintext P1.  This copy lives
// in the Phat package deliberately, so the package remains self-contained.
//
// 所有官方 V8a Phat 变体均使用同一份明文 P1。本副本刻意置于 Phat 包内，
// 以保证该包可独立使用。
.create "build/p1.bin", 0
    .headersize PrimaryP1RamAddress
    .area PrimaryP1Bytes, 0x00
    .arm

    // The mutable word at +0x04 is the ARM7-to-ARM9 command slot.  Zero parks
    // P1, one runs the local cold-start preparation, and any other value is a
    // direct ARM9 continuation supplied by P2.
    // +0x04 的可修改字是 ARM7 到 ARM9 的命令槽：零表示停驻，1 表示执行本地冷启动
    // 准备；其余值则是由 P2 提供、直接跳转的 ARM9 续接地址。
    b p1_wait_command
p1_command:
    .dw 0x00000000

p1_wait_command:
    ldr r0, [p1_command]
    cmp r0, #0
    beq p1_wait_command
    cmp r0, #1
    beq p1_cold_boot
    bx r0

p1_cold_boot:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [p1_slot_dma0_sad]

p1_clear_dma:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl p1_clear_dma

    mov r0, #1
    swi 0x1f0000
    ldr r1, [p1_slot_powercnt]
    mov r0, #0
    strh r0, [r1]

    // Map all VRAM to LCDC, erase it, then hand shared WRAM to ARM7.
    // 将全部 VRAM 映射到 LCDC、清零，然后把共享 WRAM 交给 ARM7。
    ldr r4, [p1_slot_vram_a_cr]
    ldr r5, [p1_slot_vram_lcdc_disable_all]
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    mov r1, #VRAM_A
    mov r2, #VramLcdcBytes
    bl p1_zero_halfwords
    mov r5, #(WRAM_0KARM9_32KARM7 << 24)
    strh r5, [r4]
    strh r5, [r4, #2]
    str r5, [r4, #4]
    strh r5, [r4, #8]

    ldr r0, [p1_slot_powercnt]
    ldr r1, [p1_slot_arm9_boot_state]
    strh r1, [r0]
    mov r1, #OAM
    mov r2, #MM_OBJRAM_SZ
    bl p1_zero_halfwords
    mov r1, #BG_PALETTE
    mov r2, #MM_PALRAM_SZ
    bl p1_zero_halfwords

    // Clear the two observed system-control words before releasing the next
    // primary-P1 command cycle.
    // 清除观察到的两个系统控制字，然后回到下一轮一级 P1 命令等待。
    mov r0, #0x04000000
    mov r1, #0
    str r1, [r0]
    add r0, r0, #0x1000
    str r1, [r0]
    mov r0, #0
    str r0, [p1_command]
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
p1_slot_dma0_sad:
    .dw REG_DMA0SAD
p1_slot_powercnt:
    .dw REG_POWERCNT
p1_slot_vram_a_cr:
    .dw VRAM_A_CR
p1_slot_vram_lcdc_disable_all:
    .dw VramLcdcDisableAll
p1_slot_arm9_boot_state:
    .dw Arm9BootState
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
//
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
// P1 在共享命令字为零时持续等待。P2 写入 1 时，P1 清理 ARM9 可见的 DMA、显示、
// WRAM 和两个控制字，然后把命令字清零并回到等待；P2 写入其他地址时，P1 直接跳转到
// 该 ARM9 续接地址。这使 P2 保有启动决策权，P1 只负责被请求的 ARM9 准备工作。
