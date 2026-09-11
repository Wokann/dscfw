// Stage 2 ARM7 half for FlashMe V7 Old Phat.
//
// FP2 is the route producer for FP1.  It detects the service/FlashMe route,
// publishes B/C/E through IPC_SYNC, and leaves the retained official V3 P2
// body at its original RAM entry after a 0x400-byte FlashMe prefix.
// FP2 是 FP1 的路径生产端：它检测服务/FlashMe 路径，经由 IPC_SYNC 发布 B/C/E，
// 并在 0x400 字节 FlashMe 前置代码后将保留的官方 V3 P2 主体留在原 RAM 入口。
.create "build/fp2.bin", 0
    .headersize FlashMeFp2RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    // The entry value is retained for byte/layout compatibility with V7 Old.
    // 入口值为保持 V7 Old 的字节与布局兼容而保留。
    mov r0, #7
    ldr r0, [fp2_slot_powercnt]
    mov r1, #1
    strh r1, [r0]
    mov r1, #0x3000
    swi SwiArm7SoundBiasImmediate
    bl fp2_clear_dma

    ldr r10, [fp2_slot_keyinput]
    ldrh r0, [r10]
    // KEYINPUT and KEYXY are active-low.  Select chooses the service route;
    // A+B+X+Y chooses the FlashMe route.
    // KEYINPUT 与 KEYXY 均为低有效。Select 选择服务路径；A+B+X+Y 选择 FlashMe 路径。
    tst r0, #KEY_SELECT
    beq fp2_service_boot
    ands r0, r0, #(KEY_A | KEY_B)
    bne fp2_check_boot_state
    ldrh r0, [r10, #(REG_KEYXY - REG_KEYINPUT)]
    ands r0, r0, #(KEYXY_X | KEYXY_Y)
    beq fp2_flash_boot

fp2_check_boot_state:
    // The table holds the GBA title address and DSBooter/PASS test words.
    // 表中保存 GBA 标题地址与 DSBooter/PASS 测试字。
    adr r0, fp2_boot_state
    ldmia r0, {r1-r4}
    ldmia r1, {r6-r9}
    cmp r9, r4
    beq fp2_flash_boot
    cmp r6, r2
    bne fp2_aux_probe
    cmp r7, r3
    beq fp2_flash_boot

    // The non-title route probes the auxiliary serial interface.  A successful
    // response can invoke the shared cold routine with a continuation obtained
    // from the firmware work area; otherwise the code falls through to B.
    // 非标题路径会探测辅助串行接口。成功响应可带着固件工作区中的续接进入共享冷启动
    // 例程；否则代码会顺序落入 B 路径。
fp2_aux_probe:
    bl fp2_aux_enable
    mov r0, #0xf2
    bl fp2_aux_transfer
    bl fp2_aux_transfer
    cmp r0, #0x32
    bne fp2_aux_fallback
    bl fp2_aux_transfer
    cmp r0, #0x10
    bne fp2_aux_fallback
    bl fp2_aux_clear
    bl fp2_aux_enable
    mov r0, #0xf1
    bl fp2_aux_transfer
    bl fp2_aux_clear
    mov r0, #0x8000
    strh r0, [r3]
    mov r7, #0x02100000
    mov r0, #0
    mov r1, r7
    mov r2, #0x200
    bl fp2_dma_copy
    ldr r0, [fp2_slot_word_ffff]
    add r1, r7, #0xc0
    mov r2, #0x9c
    swi 0x0e0000
    add r6, r7, #0x100
    ldrh r1, [r6, #0x5c]
    cmp r1, r0
    bne fp2_aux_fallback
    mov r0, #0x0d00
    strh r0, [r10, #0x50]
    ldr r0, [r7, #0x20]
    ldr r1, [r7, #0x28]
    ldr r2, [r7, #0x2c]
    bl fp2_dma_copy
    ldr r0, [r7, #0x30]
    ldr r1, [r7, #0x38]
    ldr r2, [r7, #0x3c]
    bl fp2_dma_copy
    bl fp2_aux_clear
    bl fp2_cold_boot
    ldr lr, [r7, #0x34]
    bx lr

fp2_aux_fallback:
    bl fp2_aux_clear
    bl fp2_aux_enable
    mov r0, #0xf0
    bl fp2_aux_transfer
    bl fp2_aux_clear

fp2_service_boot:
    mov r0, #0x0b00
    strh r0, [r10, #0x50]

    .if BuildStealth
        // Stealth B returns directly to retained P2.
        // Stealth 的 B 路径直接返回保留 P2。
        ldr lr, [fp2_slot_arm9_return]
        ldr lr, [lr]
        b fp2_retail
    .else
        // Normal V7 Old retains the service timing sequence before E.
        // 常规版 V7 Old 会在 E 之前保留服务时序。
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

    // The normal and Stealth code paths intentionally use different offsets
    // for this compact title table.  The source label keeps every branch tied
    // to the table rather than to a fixed absolute address.
    // 常规与 Stealth 路径有意为这张紧凑标题表使用不同偏移。源码标签使各分支与表绑定，
    // 而非绑定到固定绝对地址。
    .orga Fp2BootStateOffset
fp2_boot_state:
    .dw GbaRomTitleAddress
    .ascii "DSBooterPASS"

fp2_flash_boot:
    mov r0, #0x0c00
    strh r0, [r10, #0x50]
    bl fp2_cold_boot
    ldr r12, [fp2_slot_arm7_return]
    bx r12

fp2_cold_boot:
    mov r11, lr
    bl fp2_clear_dma
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

    // The entry call already cleared DMA state.  V7 Old now writes the
    // observed SPI commands directly, then rendezvous with FP1 at phase E.
    // 入口调用已经清除了 DMA 状态。V7 Old 随后直接写入已观察到的 SPI 命令，并在 E
    // 阶段与 FP1 会合。
    bl fp2_boot_return
    mov r0, #0x8a00
    mov r1, #0x84
    bl fp2_spi_write
    mov r0, #0x8200
    mov r1, #0
    bl fp2_spi_write
    mov r1, #0x0e00
fp2_wait_e:
    strh r1, [r10, #0x50]
    ldrh r0, [r10, #0x50]
    and r0, r0, #0x0f
    cmp r0, #0x0e
    bne fp2_wait_e
    bx r11

    .if BuildStealth
        .orga 0x1cc
    .else
        .orga 0x230
    .endif
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

fp2_spi_write:
    ldr r3, [fp2_slot_spicnt]
fp2_spi_wait:
    ldrh r2, [r3]
    tst r2, #0x80
    bne fp2_spi_wait
    strh r0, [r3]
    strh r1, [r3, #2]
    bx lr

fp2_clear_dma:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp2_slot_dma0_sad]
fp2_clear_dma_loop:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp2_clear_dma_loop
    bx lr

fp2_copy:
    ldr r3, [fp2_slot_bios_copy]
    bx r3

fp2_ipc_send:
    ldr r3, [fp2_slot_bios_ipc_send]
    bx r3

fp2_boot_return:
    ldr r3, [fp2_slot_bios_boot_return]
    bx r3

    // The original binary's literal pool is part of its executable layout.
    // Keep it at the observed variant-specific offset.
    // 原二进制的字面量池是可执行布局的一部分。将其保留在观察到的按变体区分的偏移。
    .if BuildStealth
        .orga 0x2c8
    .else
        .orga 0x32c
    .endif
fp2_slot_powercnt:
    .dw REG_POWERCNT
fp2_slot_keyinput:
    .dw REG_KEYINPUT
fp2_slot_word_ffff:
    .dw 0x0000ffff
fp2_slot_arm9_return:
    .dw Arm9ReturnSlotFp2
fp2_slot_arm7_return:
    .dw Arm7ReturnEntry
fp2_slot_firmware_bytes:
    .dw FlashMeFirmwareBytes
fp2_slot_header_ram:
    .dw FlashMeHeaderRamAddress
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
fp2_slot_spicnt:
    .dw REG_SPICNT
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
//     if ((REG_KEYINPUT & KEY_SELECT) == 0)
//         return false;
//     if ((REG_KEYINPUT & (KEY_A | KEY_B)) == 0 &&
//         (REG_KEYXY & (KEYXY_X | KEYXY_Y)) == 0)
//         return true;
//
//     const u32 *title = (const u32 *)GbaRomTitleAddress;
//     return title[3] == 0x53534150 ||       // PASS
//            (title[0] == 0x6f425344 &&     // DSBo
//             title[1] == 0x7265746f);      // oter
// }
//
// static __attribute__((noreturn)) void RunFp2V7(bool stealth)
// {
//     if (!SelectFlashRoute()) {
//         REG_IPC_SYNC = 0x0b00;
//         if (!stealth) {
//             RunServiceTiming();
//             REG_IPC_SYNC = 0x0e00;
//         }
//         EnterRetailP2(*(volatile u32 *)Arm9ReturnSlotFp2);
//     }
//
//     REG_IPC_SYNC = 0x0c00;
//     CopySecondaryHeaderAndPrepareSpi();
//     REG_IPC_SYNC = 0x0e00;
//     while ((REG_IPC_SYNC & 0x0f) != 0x0e) { }
//     EnterArm7ReturnEntry();
// }
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
// FP2 先按低有效按键、再按 Slot-2 标题选择路径。普通服务路径发布 B；常规版随后执行
// 服务时序并发布 E，Stealth 则立即进入保留 P2。FlashMe 路径发布 C，复制 FH、准备 SPI，
// 再与 FP1 在 E 会合。辅助 SPI 探测是一条历史的替代入口，可在验证到响应后复用冷启动
// 准备例程。
//
// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// FP2 is the second-stage ARM7 coordinator.  It is the only member that
// decides whether the retained firmware service path or FlashMe cold path runs,
// and it communicates that decision to FP1 through IPC_SYNC.  FP1 therefore
// does not race it for route selection.  The normal/Stealth condition changes
// only the B-route timing and compact-prefix layout; C continues to use the
// same header copy, peripheral setup, and E rendezvous protocol.
//
// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// FP2 是第二阶段的 ARM7 协调器。只有它决定执行保留固件服务路径还是 FlashMe 冷启动
// 路径，并通过 IPC_SYNC 将决定传给 FP1，因而 FP1 不会与它竞争路径选择。常规版与
// Stealth 的条件差异仅改变 B 路径时序及紧凑前置布局；C 路径仍使用相同的头复制、
// 外设准备与 E 会合协议。
