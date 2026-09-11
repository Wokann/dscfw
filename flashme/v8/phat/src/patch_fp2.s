// Stage 2 ARM7 half for FlashMe V8 Phat.
//
// FP2 decides whether to resume the retained service path or begin the
// FlashMe cold path.  It retains the official V3 P2 body at its original RAM
// entry after a 0x400-byte FlashMe prefix.
// FP2 决定恢复保留的服务路径还是启动 FlashMe 冷路径。它在 0x400 字节的
// FlashMe 前置区之后，将官方 V3 的 P2 主体保留在原始 RAM 入口。
.create "build/fp2.bin", 0
    .headersize FlashMeFp2RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    // V8 changes the historical entry value from seven to eight.
    // V8 将历史入口值从七改为八。
    mov r0, #8
    ldr r0, [fp2_slot_powercnt]
    mov r1, #1
    strh r1, [r0]
    mov r1, #0x3000
    swi SwiArm7SoundBiasImmediate
    bl fp2_clear_dma

    ldr r10, [fp2_slot_keyinput]
    ldrh r0, [r10]

    .if BuildNoAuto
        // NoAuto deliberately omits Select and Slot-2 title auto-detection.
        // Only the all-active-low A+B+X+Y chord selects FlashMe.
        // NoAuto 有意省略 Select 与 Slot-2 标题的自动检测。只有 A+B+X+Y
        // 同时低有效时才选择 FlashMe。
        ands r0, r0, #(KEY_A | KEY_B)
        bne fp2_service_boot
        ldrh r0, [r10, #(REG_KEYXY - REG_KEYINPUT)]
        ands r0, r0, #(KEYXY_X | KEYXY_Y)
        bne fp2_service_boot
        b fp2_flash_boot

        // The following dormant title test is retained in the NoAuto image.
        // The unconditional branch above prevents it from affecting NoAuto
        // policy, while retaining the original prefix layout and data table.
        // 下列闲置标题测试会保留在 NoAuto 镜像中。上方无条件跳转使其不会影响
        // NoAuto 策略，同时保留原始前置区布局与数据表。
fp2_retained_boot_state_check:
        adr r0, fp2_boot_state
        ldmia r0, {r1-r4}
        ldmia r1, {r6-r9}
        cmp r9, r4
        beq fp2_flash_boot
        cmp r6, r2
        bne fp2_service_boot
        cmp r7, r3
        beq fp2_flash_boot
    .else
        // KEYINPUT and KEYXY are active-low.  Select picks the service path;
        // A+B+X+Y picks FlashMe.  Otherwise V8 recognizes the DSBooter/PASS
        // Slot-2 title sequence and uses it as an automatic FlashMe route.
        // KEYINPUT 与 KEYXY 均为低有效。Select 选择服务路径；A+B+X+Y 选择
        // FlashMe。否则 V8 会识别 Slot-2 中的 DSBooter/PASS 标题序列，并将其
        // 用作自动 FlashMe 路径。
        tst r0, #KEY_SELECT
        beq fp2_service_boot
        ands r0, r0, #(KEY_A | KEY_B)
        bne fp2_check_boot_state
        ldrh r0, [r10, #(REG_KEYXY - REG_KEYINPUT)]
        ands r0, r0, #(KEYXY_X | KEYXY_Y)
        beq fp2_flash_boot

fp2_check_boot_state:
        // The table consists of the GBA title address followed by the words
        // that represent the DSBooter/PASS sequence in little-endian order.
        // 此表由 GBA 标题地址与按小端序表示 DSBooter/PASS 序列的比较字组成。
        adr r0, fp2_boot_state
        ldmia r0, {r1-r4}
        ldmia r1, {r6-r9}
        cmp r9, r4
        beq fp2_flash_boot
        cmp r6, r2
        bne fp2_service_boot
        cmp r7, r3
        beq fp2_flash_boot
    .endif

    .orga Fp2ServiceOffset
fp2_service_boot:
    mov r0, #0x0b00
    strh r0, [r10, #0x50]
    bl fp2_header_copy

    .if BuildStealth
        // Stealth returns directly to the retained official P2 after copying
        // the secondary header into its ARM7 work buffer.
        // Stealth 在将二级头复制到 ARM7 工作缓冲区后，直接返回保留的官方 P2。
        ldr lr, [fp2_slot_arm9_return]
        ldr lr, [lr]
        b fp2_retail
    .else
        // The normal Phat build retains the observed IPC timing loop before
        // it publishes E and returns to the official P2 body.
        // 常规 Phat 版会保留观测到的 IPC 时序循环，之后发布 E 并返回官方 P2 主体。
        mov r5, #0x1000
        mov r6, #0x20000
        mov r7, #0x1800

fp2_service_loop:
        mov r0, r5
        mov r4, #1
        bl fp2_ipc_call
        sub r0, r6, r5
        mov r4, #0x0d
        bl fp2_ipc_call
        add r5, r5, r7
        cmp r5, r6
        bmi fp2_service_loop
        mov r0, #0x0e00
        strh r0, [r10, #0x50]
        ldr lr, [fp2_slot_arm9_return]
        ldr lr, [lr]
        b fp2_retail

fp2_ipc_call:
        stmdb sp!, {lr}
        swi SwiArm7WaitByLoopImmediate
        mov r0, #0
        mov r1, #0
        mov r2, #1
        bl fp2_ipc_send
        mov r0, #0
        mov r1, r4
        mov r2, #0
        bl fp2_ipc_send
        ldmia sp!, {pc}
    .endif

    .orga Fp2BootStateOffset
fp2_boot_state:
    .dw GbaRomTitleAddress
    .ascii "DSBooterPASS"

    .orga Fp2FlashBootOffset
fp2_flash_boot:
    mov r0, #0x0c00
    strh r0, [r10, #0x50]
    bl fp2_cold_boot
    ldr r12, [fp2_slot_arm7_return]
    bx r12

fp2_cold_boot:
    mov r11, lr
    bl fp2_clear_dma
    bl fp2_header_copy
    bl fp2_boot_return
    mov r1, #0x8a00
    mov r0, #0x84
    bl fp2_spi_write
    mov r1, #0x8200
    mov r0, #0
    bl fp2_spi_write
    mov r1, #0x0e00
fp2_wait_e:
    strh r1, [r10, #0x50]
    ldrh r0, [r10, #0x50]
    and r0, r0, #0x0f
    cmp r0, #0x0e
    bne fp2_wait_e
    bx r11

    // These auxiliary-card and DMA helpers remain in the V8 prefix for layout
    // compatibility.  The current route selector no longer calls them.
    // 这些辅助卡与 DMA 帮助例程仍保留在 V8 前置区中以维持布局兼容；当前路径选择器
    // 已不再调用它们。
    .orga Fp2AuxOffset
fp2_aux_enable:
    ldr r0, [fp2_slot_aux_spi_control]
    ldr r3, [fp2_slot_aux_spicnt]
    strh r0, [r3]
    bx lr

fp2_aux_clear:
    ldr r3, [fp2_slot_aux_spicnt]
    mov r0, #0
    strh r0, [r3]
    bx lr

fp2_aux_transfer:
    strh r0, [r3, #2]
fp2_aux_wait:
    ldrh r0, [r3]
    tst r0, #0x80
    bne fp2_aux_wait
    ldrh r0, [r3, #2]
    bx lr

fp2_dma_copy:
    ldr r4, [fp2_slot_dma0_sad]
    mov r5, #0
    str r5, [r4, #8]
    ldr r5, [fp2_slot_gc_data_in]
    str r5, [r4]
    str r1, [r4, #4]
    ldr r5, [fp2_slot_dma_card_control]
    str r5, [r4, #8]
    ldr r3, [fp2_slot_aux_spicnt]
    mov r4, #0xa4
    strb r4, [r3, #8]
    mov r4, r0, lsr #8
    strb r4, [r3, #0x0b]
    mov r4, r4, lsr #8
    strb r4, [r3, #0x0a]
    mov r4, #0
    strb r4, [r3, #9]
    str r4, [r3, #0x0c]
    mov r4, #0xa9000000
    str r4, [r3, #4]
    add r0, r0, #0x200
    add r1, r1, #0x200
fp2_dma_wait:
    ldr r4, [r3, #4]
    tst r4, #0x80000000
    bne fp2_dma_wait
    subs r2, r2, #0x200
    bgt fp2_dma_copy
    bx lr

    // The helper is retained as bytes even though V8 Phat does not invoke its
    // two-step setup path.  Keeping it preserves the official literal-pool
    // order and prefix layout for every V8 Phat variant.
    // 虽然 V8 Phat 不调用此两步设置路径，仍保留该帮助例程的字节。这样可为所有
    // V8 Phat 变体保留官方字面量池顺序与前置区布局。
    .orga Fp2SpiSetupOffset
fp2_spi_setup:
    stmdb sp!, {r1,lr}
    ldr r1, [fp2_slot_phat_spi_initial]
    bl fp2_spi_write
    ldmia sp!, {r0,lr}
    ldr r1, [fp2_slot_phat_spi_followup]

fp2_spi_write:
    ldr r3, [fp2_slot_spicnt]
fp2_spi_wait:
    ldrh r2, [r3]
    tst r2, #0x80
    bne fp2_spi_wait
    strh r1, [r3]
    strh r0, [r3, #2]
fp2_spi_wait_read:
    ldrh r2, [r3]
    tst r2, #0x80
    bne fp2_spi_wait_read
    ldrh r1, [r3, #2]
    bx lr

    .orga Fp2ClearDmaOffset
fp2_clear_dma:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp2_slot_dma0_sad]
fp2_clear_dma_loop:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp2_clear_dma_loop
    bx lr

    .orga Fp2HeaderCopyOffset
fp2_header_copy:
    stmdb sp!, {lr}
    ldr r0, [fp2_slot_firmware_bytes]
    ldr r4, [fp2_slot_header_ram]
    mov r1, r4
    mov r2, #0x180
    bl fp2_copy
    ldrh r1, [r4, #0x70]
    add r0, r4, #0x100
    ldrh r2, [r0, #0x70]
    cmp r2, r1
    mov r1, r4
    mov r2, #0x20
    swihi SwiArm7CpuFastSetImmediate
    ldmia sp!, {pc}

    .orga Fp2CopyOffset
fp2_copy:
    ldr r3, [fp2_slot_bios_copy]
    bx r3

fp2_ipc_send:
    ldr r3, [fp2_slot_bios_ipc_send]
    bx r3

    .orga Fp2BootReturnOffset
fp2_boot_return:
    ldr r3, [fp2_slot_bios_boot_return]
    bx r3

    .orga Fp2PoolOffset
fp2_slot_powercnt:
    .dw REG_POWERCNT
fp2_slot_keyinput:
    .dw REG_KEYINPUT
fp2_slot_arm9_return:
    .dw Arm9ReturnSlotFp2
fp2_slot_arm7_return:
    .dw Arm7ReturnEntry
fp2_slot_aux_spi_control:
    .dw FlashMeAuxSpiControl
fp2_slot_aux_spicnt:
    .dw REG_AUXSPICNT
fp2_slot_dma0_sad:
    .dw REG_DMA0SAD
fp2_slot_gc_data_in:
    .dw REG_GCDATAIN
fp2_slot_dma_card_control:
    .dw DmaCardCopyControl
fp2_slot_phat_spi_initial:
    .dw PhatSpiInitialControl
fp2_slot_phat_spi_followup:
    .dw PhatSpiFollowupControl
fp2_slot_spicnt:
    .dw REG_SPICNT
fp2_slot_firmware_bytes:
    .dw FlashMeFirmwareBytes
fp2_slot_header_ram:
    .dw FlashMeHeaderRamAddress
fp2_slot_bios_copy:
    .dw BiosCopyRoutine
fp2_slot_bios_ipc_send:
    .dw BiosIpcSendRoutine
fp2_slot_bios_boot_return:
    .dw BiosBootReturnRoutine
    .endarea

fp2_retail:
    .incbin "temp/p2.bin"
fp2_retail_end:
    .if fp2_retail_end > PrimaryP2RamAddress
        .error "FlashMe: FP2 overlaps the primary P2 staging window"
    .endif
.close

// =============================================================================
// C flow model (English)
// =============================================================================
// static bool SelectFlashRoute(void)
// {
// #if BUILD_NOAUTO
//     return (REG_KEYINPUT & (KEY_A | KEY_B)) == 0 &&
//            (REG_KEYXY & (KEYXY_X | KEYXY_Y)) == 0;
// #else
//     if ((REG_KEYINPUT & KEY_SELECT) == 0)
//         return false;
//     if ((REG_KEYINPUT & (KEY_A | KEY_B)) == 0 &&
//         (REG_KEYXY & (KEYXY_X | KEYXY_Y)) == 0)
//         return true;
//     const u32 *title = (const u32 *)GbaRomTitleAddress;
//     return title[3] == 0x53534150 ||       // PASS
//            (title[0] == 0x6f425344 &&     // DSBo
//             title[1] == 0x7265746f);      // oter
// #endif
// }
//
// static __attribute__((noreturn)) void RunFp2V8Phat(bool stealth)
// {
//     if (!SelectFlashRoute()) {
//         REG_IPC_SYNC = 0x0b00;
//         CopySecondaryHeader();
//         if (!stealth) {
//             RunServiceTiming();
//             REG_IPC_SYNC = 0x0e00;
//         }
//         EnterRetailP2(*(volatile u32 *)Arm9ReturnSlotFp2);
//     }
//
//     REG_IPC_SYNC = 0x0c00;
//     ClearDma();
//     CopySecondaryHeader();
//     BiosBootReturnRoutine();
//     SpiWrite(0x8a00, 0x84);
//     SpiWrite(0x8200, 0x00);
//     REG_IPC_SYNC = 0x0e00;
//     while ((REG_IPC_SYNC & 0x0f) != 0x0e) { }
//     EnterArm7ReturnEntry();
// }

// =============================================================================
// C 流程模型（中文）
// =============================================================================
// NoAuto 只接受低有效的 A+B+X+Y 组合；其余变体还会将 Select 作为服务路径选择，
// 并检查 Slot-2 的 DSBooter/PASS 标题。服务路径先发布 B 并复制二级头；常规 Phat
// 继续执行 IPC 时序、发布 E，Stealth 则直接进入保留 P2。冷启动路径发布 C、清除 DMA、
// 复制二级头、调用 BIOS 返回准备，写入两个最终 SPI 命令，再在 E 与 FP1 会合。

// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// FP2 is the ARM7 owner of second-stage routing.  Its B/C/E IPC phases make
// FP1 a follower: FP1 prepares ARM9 only after FP2 commits to C, so the two
// processors cannot independently choose incompatible boot paths.  V8 keeps
// old auxiliary and two-step SPI helper blocks for binary layout compatibility,
// but its Phat route deliberately executes only the final two SPI writes.  The
// NoAuto condition removes policy inputs rather than changing the underlying
// B/C/E handshake or retained-component placement.

// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// FP2 是二级路径的 ARM7 所有者。它的 B/C/E IPC 阶段使 FP1 成为跟随者：只有 FP2
// 确认进入 C 后，FP1 才准备 ARM9，因此两颗 CPU 不会独立选择彼此冲突的启动路径。V8
// 为二进制布局兼容而保留旧辅助卡及两步 SPI 帮助块，但 Phat 路径刻意只执行最终两次 SPI
// 写入。NoAuto 只是移除选择策略的输入，不改变底层 B/C/E 握手或保留组件的放置方式。
