// Stage 2 ARM7 half for FlashMe V8 Lite.
//
// FP2 decides whether to resume the retained service path or begin the
// FlashMe cold path.  It retains the official V6 P2 body at its original RAM
// entry after a 0x400-byte FlashMe prefix.
// FP2 决定恢复保留的服务路径还是启动 FlashMe 冷路径。它在 0x400 字节的
// FlashMe 前置区之后，将官方 V6 的 P2 主体保留在原始 RAM 入口。
.create "build/fp2.bin", 0
    .headersize FlashMeFp2RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    // V8 changes the historical entry value from seven to eight.
    // V8 将历史入口值从七改为八。
    mov r0, #8
    ldr r0, =REG_POWERCNT
    mov r1, #1
    strh r1, [r0]
    .dw 0xe3a01dc0 // mov r1, #0x3000, historical immediate encoding
    swi SwiArm7SoundBiasImmediate
    bl fp2_clear_dma

    ldr r10, =REG_KEYINPUT
    ldrh r0, [r10]

    .if BuildNoAuto
        // NoAuto accepts only the all-active-low A+B+X+Y chord.  The dormant
        // title test below is intentionally retained as unreachable layout
        // data/code from the official NoAuto image.
        // NoAuto 只接受同时低有效的 A+B+X+Y 组合。下方闲置标题测试会作为官方
        // NoAuto 镜像中不可达的布局代码/数据而有意保留。
        ands r0, r0, #(KEY_A | KEY_B)
        bne fp2_service_boot
        ldrh r0, [r10, #(REG_KEYXY - REG_KEYINPUT)]
        ands r0, r0, #(KEYXY_X | KEYXY_Y)
        bne fp2_service_boot
        b fp2_flash_boot

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
    .dw 0xe3a00eb0 // mov r0, #0x0b00
    strh r0, [r10, #0x50]
    bl fp2_header_copy

    .if BuildStealth
        // Stealth returns directly to retained official P2 after copying FH.
        // Stealth 在复制 FH 后直接返回保留的官方 P2。
        ldr lr, =Arm9ReturnSlotFp2
        ldr lr, [lr]
        b fp2_retail
    .else
        // The ordinary Lite B route has the V8 delay sequence rather than the
        // Phat IPC timing loop.  The following retained IPC helper is present
        // in the image for compatibility but is not called by this path.
        // 常规 Lite B 路径使用 V8 延时序列，而不是 Phat 的 IPC 时序循环。紧随其后
        // 的保留 IPC 帮助例程为兼容而存在，但此路径不会调用它。
        .dw 0xe3a009a0 // mov r0, #0x280000
        swi SwiArm7WaitByLoopImmediate
        .dw 0xe3a00ee0 // mov r0, #0x0e00
        strh r0, [r10, #0x50]
        ldr lr, =Arm9ReturnSlotFp2
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
    .dw 0xe3a00ec0 // mov r0, #0x0c00
    strh r0, [r10, #0x50]
    bl fp2_cold_boot
    ldr r12, =Arm7ReturnEntry
    bx r12

fp2_cold_boot:
    mov r11, lr
    bl fp2_clear_dma
    bl fp2_header_copy
    bl fp2_boot_return
    .dw 0xe3a01c8a // mov r1, #0x8a00
    mov r0, #0x84
    bl fp2_lite_spi_write
    .dw 0xe3a01c82 // mov r1, #0x8200
    mov r0, #0
    bl fp2_lite_spi_write
    .dw 0xe3a01ee0 // mov r1, #0x0e00
fp2_wait_e:
    strh r1, [r10, #0x50]
    ldrh r0, [r10, #0x50]
    and r0, r0, #0x0f
    cmp r0, #0x0e
    bne fp2_wait_e
    bx r11

    // These auxiliary-card and DMA helpers remain in the V8 prefix for layout
    // compatibility.  The V8 route selector no longer calls them directly.
    // 这些辅助卡与 DMA 帮助例程仍保留在 V8 前置区中以维持布局兼容；V8 路径选择器
    // 不再直接调用它们。
    .orga Fp2AuxOffset
fp2_aux_enable:
    ldr r0, =FlashMeAuxSpiControl
    ldr r3, =REG_AUXSPICNT
    strh r0, [r3]
    bx lr

fp2_aux_clear:
    ldr r3, =REG_AUXSPICNT
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
    ldr r4, =REG_DMA0SAD
    mov r5, #0
    str r5, [r4, #8]
    ldr r5, =REG_GCDATAIN
    str r5, [r4]
    str r1, [r4, #4]
    ldr r5, =DmaCardCopyControl
    str r5, [r4, #8]
    ldr r3, =REG_AUXSPICNT
    mov r4, #0xa4
    strb r4, [r3, #8]
    mov r4, r0, lsr #8
    strb r4, [r3, #0x0b]
    mov r4, r4, lsr #8
    strb r4, [r3, #0x0a]
    mov r4, #0
    strb r4, [r3, #9]
    str r4, [r3, #0x0c]
    .dw 0xe3a044a9 // mov r4, #0xa9000000
    str r4, [r3, #4]
    .dw 0xe2800f80 // add r0, r0, #0x200
    .dw 0xe2811f80 // add r1, r1, #0x200
fp2_dma_wait:
    ldr r4, [r3, #4]
    .dw 0xe3140480 // tst r4, #0x80000000
    bne fp2_dma_wait
    .dw 0xe2522f80 // subs r2, r2, #0x200
    bgt fp2_dma_copy
    bx lr

    .orga Fp2SpiSetupOffset
fp2_lite_setup:
    stmdb sp!, {r1,lr}
    ldr r1, =LiteSpiInitialControl
    bl fp2_lite_spi_write
    ldmia sp!, {r0,lr}
    ldr r1, =LiteSpiFollowupControl

fp2_lite_spi_write:
    ldr r3, =REG_SPICNT
fp2_lite_spi_wait:
    ldrh r2, [r3]
    tst r2, #0x80
    bne fp2_lite_spi_wait
    strh r1, [r3]
    strh r0, [r3, #2]
fp2_lite_spi_wait_read:
    ldrh r2, [r3]
    tst r2, #0x80
    bne fp2_lite_spi_wait_read
    ldrh r1, [r3, #2]
    bx lr

    .orga Fp2ClearDmaOffset
fp2_clear_dma:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, =REG_DMA0SAD
fp2_clear_dma_loop:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp2_clear_dma_loop
    bx lr

    .orga Fp2HeaderCopyOffset
fp2_header_copy:
    stmdb sp!, {lr}
    ldr r0, =FlashMeFirmwareBytes
    ldr r4, =FlashMeHeaderRamAddress
    mov r1, r4
    .dw 0xe3a02f60 // mov r2, #0x180
    bl fp2_copy
    ldrh r1, [r4, #0x70]
    .dw 0xe2840f40 // add r0, r4, #0x100
    ldrh r2, [r0, #0x70]
    cmp r2, r1
    mov r1, r4
    mov r2, #0x20
    swihi SwiArm7CpuFastSetImmediate

    // Lite executes the two-step SPI setup for every V8 variant.  If the
    // returned status exposes bit 6, the low field is derived from FH + 0x64.
    // Lite 会为每个 V8 变体执行两步 SPI 设置。若返回状态具有 bit 6，则低字段
    // 从 FH + 0x64 派生。
    mov r0, #0x84
    mov r1, #0
    bl fp2_lite_setup
    tst r1, #0x40
    beq fp2_lite_setup_done
    ldrb r0, [r4, #0x64]
    and r1, r1, #0xfc
    orr r1, r1, r0, lsr #4
    mov r0, #4
    bl fp2_lite_setup
fp2_lite_setup_done:
    ldmia sp!, {pc}

    .orga Fp2CopyOffset
fp2_copy:
    ldr r3, =BiosCopyRoutine
    bx r3

    // Retained in all V8 Lite variants for the original prefix and pool
    // layout.  The V8 service route does not call it.
    // 为保留原始前置区及 pool 布局而在所有 V8 Lite 变体中保留。V8 服务路径不调用它。
fp2_ipc_send:
    ldr r3, =BiosIpcSendRoutine
    bx r3

    .orga Fp2BootReturnOffset
fp2_boot_return:
    ldr r3, =BiosBootReturnRoutine
    bx r3

    .orga Fp2PoolOffset
    .pool
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
// static __attribute__((noreturn)) void RunFp2V8Lite(bool stealth)
// {
//     if (!SelectFlashRoute()) {
//         REG_IPC_SYNC = 0x0b00;
//         CopySecondaryHeaderAndPrepareLiteSpi();
//         if (!stealth) {
//             swiWaitByLoop(0x280000);
//             REG_IPC_SYNC = 0x0e00;
//         }
//         EnterRetailP2(*(volatile u32 *)Arm9ReturnSlotFp2);
//     }
//
//     REG_IPC_SYNC = 0x0c00;
//     ClearDma();
//     CopySecondaryHeaderAndPrepareLiteSpi();
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
// 并检查 Slot-2 的 DSBooter/PASS 标题。服务路径先发布 B、复制 FH 并准备 Lite SPI；
// 常规 Lite 随后执行固定延时并发布 E，Stealth 直接进入保留 P2。冷启动路径发布 C、
// 清除 DMA、复制 FH/准备 SPI、调用 BIOS 返回准备，写入最终两次 SPI 命令，最后在 E
// 与 FP1 会合。

// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// FP2 owns ARM7-side second-stage routing and serializes FP1 through B/C/E
// IPC phases.  Thus FP1 only prepares ARM9 after FP2 has established the cold
// path.  V8 Lite differs from V8 Phat in two concrete places: its normal B
// route uses a BIOS loop delay, and every variant runs the observed two-step
// Lite SPI preparation while copying FH.  The auxiliary, DMA, and unused IPC
// helper blocks remain byte-for-byte layout members even though current route
// selection does not invoke all of them.

// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// FP2 拥有 ARM7 侧的二级路径选择权，并通过 B/C/E IPC 阶段将 FP1 串行化。因此只有 FP2
// 确定冷路径后，FP1 才会准备 ARM9。V8 Lite 与 V8 Phat 有两项明确差异：常规 B 路径使用
// BIOS 循环延时，且每个变体都会在复制 FH 时执行观测到的两步 Lite SPI 准备。辅助卡、DMA
// 与未使用 IPC 帮助块即使当前路径选择并不会全部调用，也仍作为逐字节布局成员保留。
