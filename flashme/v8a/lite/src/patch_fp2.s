// FlashMe V8a Lite second-stage ARM7 prefix.
//
// FP2 owns second-stage route selection and serializes FP1 by publishing B/C/E
// through IPC_SYNC.  Retained official V6 P2 begins after this 0x400-byte prefix.
//
// FP2 掌握二级路径选择，并通过 IPC_SYNC 发布 B/C/E 以串行化 FP1。保留的官方 V6 P2
// 紧接在这个 0x400 字节前置区之后。
.create "build/fp2.bin", 0
    .headersize FlashMeFp2RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

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
        // Official V8a NoAuto uses Select as its explicit FlashMe request.
        // The retained title-test block is deliberately unreachable layout data.
        // 官方 V8a NoAuto 以 Select 作为明确的 FlashMe 请求；保留的标题测试块
        // 刻意作为不可达布局数据保留。
        tst r0, #KEY_SELECT
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
        // KEYINPUT/KEYXY are active-low.  Select retains service; A+B+X+Y or
        // a DSBooter/PASS title chooses the FlashMe route.
        // KEYINPUT/KEYXY 为低有效：Select 保留服务路径；A+B+X+Y 或
        // DSBooter/PASS 标题选择 FlashMe 路径。
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
    mov r0, #0x0b00
    strh r0, [r10, #0x50]
    bl fp2_header_copy

    .if BuildStealth
        // Stealth returns straight to retained ARM7 after copying FH.
        // Stealth 在复制 FH 后直接返回保留 ARM7。
        ldr lr, [fp2_slot_arm9_return]
        ldr lr, [lr]
        b fp2_retail
    .else
        // Normal Lite uses the observed BIOS-loop delay before phase E.
        // 常规 Lite 在 E 阶段前使用观测到的 BIOS 循环延时。
        mov r0, #0x280000
        swi SwiArm7WaitByLoopImmediate
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
    bl fp2_lite_spi_write
    mov r1, #0x8200
    mov r0, #0
    bl fp2_lite_spi_write
    mov r1, #0x0e00

fp2_wait_e:
    strh r1, [r10, #0x50]
    ldrh r0, [r10, #0x50]
    and r0, r0, #0x0f
    cmp r0, #0x0e
    bne fp2_wait_e
    bx r11

    // Retained auxiliary-card/DMA helpers preserve the official V8a layout.
    // 保留辅助卡/DMA 帮助例程以维持官方 V8a 布局。
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

    .orga Fp2SpiSetupOffset
fp2_lite_setup:
    stmdb sp!, {r1,lr}
    ldr r1, [fp2_slot_lite_spi_initial]
    bl fp2_lite_spi_write
    ldmia sp!, {r0,lr}
    ldr r1, [fp2_slot_lite_spi_followup]

fp2_lite_spi_write:
    ldr r3, [fp2_slot_spicnt]
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

    // Lite performs the two-step SPI setup for every V8a variant.
    // Lite 会为每个 V8a 变体执行两步 SPI 设置。
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
fp2_slot_lite_spi_initial:
    .dw LiteSpiInitialControl
fp2_slot_lite_spi_followup:
    .dw LiteSpiFollowupControl
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
//
// static bool SelectV8aLiteRoute(void)
// {
// #if BUILD_NOAUTO
//     return (REG_KEYINPUT & KEY_SELECT) == 0;
// #else
//     if ((REG_KEYINPUT & KEY_SELECT) == 0)
//         return false;
//     if ((REG_KEYINPUT & (KEY_A | KEY_B)) == 0 &&
//         (REG_KEYXY & (KEYXY_X | KEYXY_Y)) == 0)
//         return true;
//     return IsDsBooterOrPassTitle((const char *)GbaRomTitleAddress);
// #endif
// }
//
// FP2 publishes B for retained service and C/E for a FlashMe cold boot.  Lite
// uses its observed delay on the normal B route and its two-step SPI setup in
// every variant.
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
//
// NoAuto 仅在 Select 被按下时选择 FlashMe；其他变体还接受 A+B+X+Y 组合及
// DSBooter/PASS 标题。FP2 为保留服务路径发布 B，为冷启动发布 C/E。Lite 的常规 B
// 路径采用观测到的延时，且所有变体均执行两步 SPI 设置。
