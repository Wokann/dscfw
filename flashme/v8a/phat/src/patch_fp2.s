
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

    .org FlashMeFp2RamAddress + Fp2ServiceOffset
fp2_service_boot:
    mov r0, #0x0b00
    strh r0, [r10, #0x50]
    bl fp2_header_copy
    .if BuildStealth
        ldr lr, [fp2_slot_arm9_return]
        ldr lr, [lr]
        b fp2_retail
    .else

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

    .org FlashMeFp2RamAddress + Fp2BootStateOffset
fp2_boot_state:
    .dw GbaRomTitleAddress
    .ascii "DSBooterPASS"

    .org FlashMeFp2RamAddress + Fp2FlashBootOffset
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

    .org FlashMeFp2RamAddress + Fp2AuxOffset
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

    .org FlashMeFp2RamAddress + Fp2SpiSetupOffset
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

    .org FlashMeFp2RamAddress + Fp2ClearDmaOffset
fp2_clear_dma:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp2_slot_dma0_sad]
fp2_clear_dma_loop:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp2_clear_dma_loop
    bx lr

    .org FlashMeFp2RamAddress + Fp2HeaderCopyOffset
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

    .org FlashMeFp2RamAddress + Fp2CopyOffset
fp2_copy:
    ldr r3, [fp2_slot_bios_copy]
    bx r3

fp2_ipc_send:
    ldr r3, [fp2_slot_bios_ipc_send]
    bx r3

    .org FlashMeFp2RamAddress + Fp2BootReturnOffset
fp2_boot_return:
    ldr r3, [fp2_slot_bios_boot_return]
    bx r3

    .org FlashMeFp2RamAddress + Fp2PoolOffset
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

    .org RetailP2RamAddress
    .incbin "temp/p2.bin"
.close
