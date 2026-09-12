
.create "build/p2.bin", 0
    .headersize PrimaryP2RamAddress
    .arm
    adr r0, p2_thumb + 1
    bx r0

    .thumb

p2_thumb:
    mov r11, r12
    mov r1, #0
    mov r2, #1
    bl p2_write_power_management
    mov r1, #0x0d
    mov r2, #0
    bl p2_write_power_management

    adr r7, p2_boot_parameters_data
    ldmia r7!, {r0-r2, r4-r6}
    ldrh r1, [r1]
    lsl r1, r1, #28
    beq p2_boot_slot2
    ldr r1, [r6]
    cmp r1, r2
    bne p2_load_secondary_p12

p2_boot_slot2:
    ldmia r7!, {r0-r4}
    stmia r3!, {r0-r2}

    str r0, [r4, #0x0c]
    add r6, #0x14
    b p2_handoff

p2_write_power_management:
    ldr r3, [p2_slot_swi_routine]
    mov r0, #0
    bx r3

    .org PrimaryP2RamAddress + 0x3a
p2_boot_parameters:

    .dh 0x0000
p2_boot_parameters_data:
    .dw FlashMeSecondaryHeaderAddress, REG_KEYINPUT
    .ascii "BOOT"
    .dw Bios7FirmwareRead, Bios7Lz77UncompVram, 0x080000ac

p2_arm9_trampoline_entry:
    .dw NdsCartHeaderRetailArm9RamAddress
    .arm
p2_arm9_trampoline_load:
    ldr r0, [p2_arm9_trampoline_entry]
    bx r0
    .thumb
p2_arm9_trampoline_return_slot:
    .dw NdsCartHeaderRetailArm9EntryAddress
p2_arm9_trampoline_primary_p1:
    .dw PrimaryP1RamAddress

    .org PrimaryP2RamAddress + 0x68
p2_load_secondary_p12:

    mov r1, r11
    mov r2, #0x70
    bl p2_cpu_fast_set
    mov r7, r11
    ldrh r4, [r7, #0x14]
    ldr r1, [p2_slot_part1_ram_base]
    bl p2_compute_address
    ldr r1, [p2_slot_part2_ram_base]
    lsr r4, r4, #6
    add r7, #4
    bl p2_compute_address
    pop {r6, r7}
    ldr r4, [p2_slot_primary_p1_ram]

    str r7, [r4, #0x0c]

p2_handoff:
    mov lr, r6
    mov r0, sp
    mov r1, r11
    mov r2, #0xff
    ldr r4, [p2_slot_bios_cpu_fast_set]

p2_cpu_fast_set:
    bx r4

p2_compute_address:
    ldrh r0, [r7, #0x0c]
    ldrh r2, [r7, #0x0e]
    lsl r3, r4, #29
    lsr r3, r3, #29
    lsl r0, r3
    lsl r0, r0, #2
    lsl r3, r4, #26
    lsr r3, r3, #29
    lsl r2, r3
    lsl r2, r2, #2
    sub r1, r1, r2
    adr r3, p2_firmware_read_callback_table
    push {r1}
    bx r5

    .org PrimaryP2RamAddress + 0xb2

p2_firmware_read_callback:
    push {r0, lr}
    mov r2, #0
    ldr r3, [p2_slot_bios_firmware_read_begin]
    bl p2_bios_call
    mov r0, sp
    mov r1, #4
    mov r2, #1
    ldr r3, [p2_slot_bios_spi_transfer_buffer]
    bl p2_bios_call
    ldr r1, [p2_slot_spidata]
    strh r0, [r1]
    pop {r0, r3}

p2_bios_call:
    bx r3

p2_spi_wait_transfer:
    ldr r1, [p2_slot_spicnt]
p2_spi_wait_transfer_busy:
    ldrh r0, [r1]
    lsr r0, r0, #8

    bcs p2_spi_wait_transfer_busy
    ldrb r0, [r1, #2]
    strh r0, [r1, #2]
    bx lr

    .org PrimaryP2RamAddress + 0xe0

p2_firmware_read_callback_table:
    .dw p2_firmware_read_callback + 1
    .dw Bios7SpiTransferFinish
    .dw p2_spi_wait_transfer + 1

p2_slot_swi_routine:
    .dw Bios7PowerManagementWrite
p2_slot_part1_ram_base:
    .dw FirmwarePart1RamaddrEncodingBase
p2_slot_part2_ram_base:
    .dw FirmwarePart2RamaddrEncodingBase
p2_slot_primary_p1_ram:
    .dw PrimaryP1RamAddress
p2_slot_bios_cpu_fast_set:
    .dw Bios7CpuFastSetArm
p2_slot_bios_firmware_read_begin:
    .dw Bios7FirmwareReadBegin
p2_slot_bios_spi_transfer_buffer:
    .dw Bios7SpiTransferBuffer
p2_slot_spidata:
    .dw REG_SPIDATA
p2_slot_spicnt:
    .dw REG_SPICNT
p2_primary_end:

    .if p2_primary_end > FirmwarePart2RamaddrEncodingBase
        .error "FlashMe: primary P2 exceeds its staging window"
    .endif
.close
