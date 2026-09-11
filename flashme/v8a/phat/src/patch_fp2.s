// FlashMe V8a Phat second-stage ARM7 prefix.
//
// FP2 owns second-stage route selection.  It publishes B/C/E through IPC_SYNC
// so FP1 cannot independently select a conflicting ARM9 path.
//
// FP2 掌握二级路径选择，并通过 IPC_SYNC 发布 B/C/E，使 FP1 不会独立选择冲突的
// ARM9 路径。
.create "build/fp2.bin", 0
    .headersize FlashMeFp2RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    mov r0, #8
    ldr r0, =REG_POWERCNT
    mov r1, #1
    strh r1, [r0]
    .dw 0xe3a01dc0 // mov r1, #0x3000
    swi SwiArm7SoundBiasImmediate
    bl fp2_clear_dma
    ldr r10, =REG_KEYINPUT
    ldrh r0, [r10]

    .if BuildNoAuto
        // Official V8a NoAuto uses Select as the explicit FlashMe request;
        // the retained title-test block below is intentionally unreachable.
        // 官方 V8a NoAuto 以 Select 作为显式 FlashMe 请求；下方保留的标题测试块
        // 会有意保持不可达。
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
        // KEYINPUT/KEYXY are active-low.  Select requests retail service;
        // A+B+X+Y or the DSBooter/PASS title requests FlashMe.
        // KEYINPUT/KEYXY 为低有效：Select 请求零售服务；A+B+X+Y 或
        // DSBooter/PASS 标题请求 FlashMe。
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
        ldr lr, =Arm9ReturnSlotFp2
        ldr lr, [lr]
        b fp2_retail
    .else
        // V8a Phat keeps the observed IPC timing loop before phase E.
        // V8a Phat 在发布 E 前保留观测到的 IPC 时序循环。
        .dw 0xe3a05d40 // mov r5, #0x1000
        .dw 0xe3a06b80 // mov r6, #0x20000
        .dw 0xe3a07d60 // mov r7, #0x1800

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
    bl fp2_spi_write
    .dw 0xe3a01c82 // mov r1, #0x8200
    mov r0, #0
    bl fp2_spi_write
    .dw 0xe3a01ee0 // mov r1, #0x0e00

fp2_wait_e:
    strh r1, [r10, #0x50]
    ldrh r0, [r10, #0x50]
    and r0, r0, #0x0f
    cmp r0, #0x0e
    bne fp2_wait_e
    bx r11

    // Retained auxiliary-card / DMA helpers preserve the official V8a layout.
    // 保留辅助卡 / DMA 帮助例程以维持官方 V8a 布局。
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
fp2_spi_setup:
    stmdb sp!, {r1,lr}
    ldr r1, =PhatSpiInitialControl
    bl fp2_spi_write
    ldmia sp!, {r0,lr}
    ldr r1, =PhatSpiFollowupControl

fp2_spi_write:
    ldr r3, =REG_SPICNT
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
    ldmia sp!, {pc}

    .orga Fp2CopyOffset
fp2_copy:
    ldr r3, =BiosCopyRoutine
    bx r3

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
.close

// =============================================================================
// C flow model (English)
// =============================================================================
//
// static bool SelectV8aRoute(void)
// {
// #if BUILD_NOAUTO
//     return (REG_KEYINPUT & KEY_SELECT) == 0;
// #else
//     if ((REG_KEYINPUT & KEY_SELECT) == 0) return false;
//     if ((REG_KEYINPUT & (KEY_A | KEY_B)) == 0 &&
//         (REG_KEYXY & (KEYXY_X | KEYXY_Y)) == 0) return true;
//     return IsDsBooterOrPassTitle((const char *)GbaRomTitleAddress);
// #endif
// }
//
// FP2 publishes B for the retail service route and C/E for cold FlashMe boot.
// The Phat normal route retains its observed IPC timing loop; Stealth skips it.
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
//
// NoAuto 仅在 Select 被按下时选择 FlashMe；其他变体还接受 A+B+X+Y 组合及
// DSBooter/PASS 标题。FP2 为零售服务路径发布 B，为冷启动发布 C/E。Phat 常规版
// 保留观测到的 IPC 时序循环，Stealth 则跳过该循环。
