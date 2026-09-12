; FlashMe boot7 / FP2: ARM7 secondary boot component.
; FlashMe boot7 / FP2：ARM7 次级启动组件。

.create "build/fp2.bin", 0
    .headersize FlashMeFp2RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    mov r0, #6
    ldr r0, [fp2_slot_powercnt]
    mov r1, #1
    strh r1, [r0]

    mov r1, #0x3000
    swi SwiSoundBias
    ldr r10, [fp2_slot_keyinput]
    ldrh r0, [r10]

    tst r0, #KEY_SELECT
    beq fp2_retail_boot

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
    bne fp2_retail_boot
    cmp r7, r3
    beq fp2_flash_boot

fp2_retail_boot:

    mov r0, #0x0b00
    strh r0, [r10, #0x50]

    .if BuildStealth
    ldr lr, [fp2_slot_arm9_return]
    ldr lr, [lr]
    b fp2_retail_boot_code
    .else
    mov r5, #0x1000
    mov r6, #0x20000
    mov r7, #0x1800

fp2_service_loop:
    mov r0, r5
    mov r4, #1
    bl fp2_backlight_fade_step
    sub r0, r6, r5
    mov r4, #0x0d
    bl fp2_backlight_fade_step
    add r5, r5, r7
    cmp r5, r6
    bmi fp2_service_loop
    mov r0, #0x0d00
    strh r0, [r10, #0x50]
    ldr lr, [fp2_slot_arm9_return]
    ldr lr, [lr]
    b fp2_retail_boot_code

fp2_backlight_fade_step:
    stmdb sp!, {lr}
    swi SwiWaitByLoop
    mov r0, #0
    mov r1, #0
    mov r2, #1
    bl fp2_write_power_management
    mov r0, #0
    mov r1, r4
    mov r2, #0
    bl fp2_write_power_management
    ldmia sp!, {pc}
    .endif

    .org FlashMeFp2RamAddress + (BuildStealth ? 0x074 : 0x0d8)
fp2_boot_state:
    .dw GbaRomTitleAddress
fp2_boot_signature:
    .ascii "DSBooterPASS"

fp2_flash_boot:

    mov r0, #0x0c00
    strh r0, [r10, #0x50]
    ldr r0, [fp2_slot_firmware_bytes]
    ldr r4, [fp2_slot_header_ram]
    mov r1, r4
    mov r2, #0x180
    bl fp2_read_firmware
    ldrh r1, [r4, #0x70]
    add r0, r4, #0x100
    ldrh r2, [r0, #0x70]
    cmp r2, r1
    mov r1, r4
    mov r2, #0x20
    swihi SwiCpuFastSet
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp2_slot_dma0_src]

fp2_clear_dma_range:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp2_clear_dma_range

    bl fp2_signal_boot_finish
    mov r0, #0x00008a00
    mov r1, #0x00000084
    bl fp2_spi_write
    mov r0, #0x00008200
    mov r1, #0
    bl fp2_spi_write
    mov r1, #0x0d00

fp2_wait_d:
    strh r1, [r10, #0x50]
    ldrh r0, [r10, #0x50]
    and r0, r0, #0x0f
    cmp r0, #0x0d
    bne fp2_wait_d
    ldr r12, [fp2_slot_arm7_return]
    bx r12

fp2_spi_write:
    ldr r3, [fp2_slot_spicnt]

fp2_spi_wait:
    ldrh r2, [r3]
    tst r2, #0x80
    bne fp2_spi_wait
    strh r0, [r3]
    strh r1, [r3, #2]
    bx lr

fp2_read_firmware:
    ldr r3, [fp2_slot_bios_copy]
    bx r3

fp2_write_power_management:
    ldr r3, [fp2_slot_bios_ipc_send]
    bx r3

fp2_signal_boot_finish:
    ldr r3, [fp2_slot_bios_boot_return]
    bx r3

fp2_slot_padding:
    .dw 0x00000000

fp2_slot_powercnt:
    .dw REG_POWERCNT
fp2_slot_keyinput:
    .dw REG_KEYINPUT
fp2_slot_arm9_return:
    .dw NdsCartHeaderArm7EntryAddress
fp2_slot_firmware_bytes:
    .dw FirmwareUserSettingsAddress256K
fp2_slot_header_ram:
    .dw FirmwareUserSettingsRamAddress
fp2_slot_dma0_src:
    .dw REG_DMA0SAD
fp2_slot_arm7_return:
    .dw GbaArm7Entry
fp2_slot_spicnt:
    .dw REG_SPICNT
fp2_slot_bios_copy:
    .dw Bios7FirmwareRead
fp2_slot_bios_ipc_send:
    .dw Bios7PowerManagementWrite
fp2_slot_bios_boot_return:
    .dw Bios7SignalBootFinish
    .endarea

fp2_retail_boot_code:

    .org RetailP2RamAddress

    .incbin "temp/p2.bin"
fp2_retail_end:

    .if fp2_retail_end > PrimaryP2RamAddress
        .error "FlashMe: FP2 overlaps the primary P2 staging window"
    .endif
.close
