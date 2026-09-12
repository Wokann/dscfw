
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
    bl p2_swi
    mov r1, #0x0d
    mov r2, #0
    bl p2_swi

    adr r7, p2_boot_parameters_data
    ldmia r7!, {r0-r2, r4-r6}
    ldrh r1, [r1]
    lsl r1, r1, #28
    beq p2_copy_boot
    ldr r1, [r6]
    cmp r1, r2
    bne p2_service_boot

p2_copy_boot:
    ldmia r7!, {r0-r4}
    stmia r3!, {r0-r2}

    str r0, [r4, #PrimaryP1ReleaseSlotOffset]
    add r6, #0x14
    b p2_handoff

p2_swi:
    ldr r3, [p2_slot_swi_routine]
    mov r0, #0
    bx r3

    .org PrimaryP2RamAddress + 0x3a
p2_boot_parameters:

    .dh 0x0000
p2_boot_parameters_data:
    .dw FlashMePrimaryHeaderAddress, REG_KEYINPUT
    .ascii "BOOT"
    .dw BiosCopyRoutine, 0x00002a2b, 0x080000ac

p2_arm9_trampoline_entry:
    .dw 0x023ffe28
    .arm
p2_arm9_trampoline_load:
    ldr r0, [p2_arm9_trampoline_entry]
    bx r0
    .thumb
p2_arm9_trampoline_return_slot:
    .dw 0x023ffe24
p2_arm9_trampoline_primary_p1:
    .dw PrimaryP1RamAddress

    .org PrimaryP2RamAddress + 0x68
p2_service_boot:

    mov r1, r11
    mov r2, #0x70
    bl p2_compute
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

    str r7, [r4, #PrimaryP1ReleaseSlotOffset]

p2_handoff:
    mov lr, r6
    mov r0, sp
    mov r1, r11
    mov r2, #0xff
    ldr r4, [p2_slot_compute_routine]

p2_compute:
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
    adr r3, p2_legacy_callback_table
    push {r1}
    bx r5

    .org PrimaryP2RamAddress + 0xb2

p2_legacy_thunk:
    push {r0, lr}
    mov r2, #0
    ldr r3, [p2_slot_legacy_call]
    bl p2_legacy_call
    mov r0, sp
    mov r1, #4
    mov r2, #1
    ldr r3, [p2_slot_legacy_copy]
    bl p2_legacy_call
    ldr r1, [p2_slot_spidata]
    strh r0, [r1]
    pop {r0, r3}

p2_legacy_call:
    bx r3

p2_legacy_wait:
    ldr r1, [p2_slot_spicnt]

p2_legacy_wait_busy:
    ldrh r0, [r1]
    lsr r0, r0, #8
    bcs p2_legacy_wait_busy
    ldrb r0, [r1, #2]
    strh r0, [r1, #2]
    bx lr

    .org PrimaryP2RamAddress + 0xe0

p2_legacy_callback_table:
    .dw p2_legacy_thunk + 1
    .dw PrimaryP2LegacyCallbackValue
    .dw p2_legacy_wait + 1

p2_slot_swi_routine:
    .dw PrimaryP2SwiRoutine
p2_slot_part1_ram_base:
    .dw FirmwarePart1RamaddrBase
p2_slot_part2_ram_base:
    .dw FirmwarePart2RamaddrBase
p2_slot_primary_p1_ram:
    .dw PrimaryP1RamAddress
p2_slot_compute_routine:
    .dw PrimaryP2ComputeRoutine
p2_slot_legacy_call:
    .dw PrimaryP2LegacyCallRoutine
p2_slot_legacy_copy:
    .dw PrimaryP2LegacyCopyRoutine
p2_slot_spidata:
    .dw REG_SPIDATA
p2_slot_spicnt:
    .dw REG_SPICNT
p2_primary_end:

    .if p2_primary_end > FirmwarePart2RamaddrBase
        .error "FlashMe: primary P2 exceeds its staging window"
    .endif
.close
