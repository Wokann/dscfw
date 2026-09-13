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
    lsr r1, r1, #30
    beq p2_recovery_boot
    ldr r1, [r6]
    cmp r1, r2
    bne p2_load_secondary_p12

; Start+Select/BOOT: prepare both CPUs, then use B7 Slot-1 loading or Slot-2 fallback. See after .close.
; Start+Select/BOOT：准备双 CPU，再用 B7 Slot-1 装载或 Slot-2 回退。详见 .close 后。
p2_recovery_boot:
    ; Start+Select or BOOT enters this route; state later chooses standard Slot-1 load or Slot-2 fallback.
    ; Start+Select 或 BOOT 进入此路径；稍后由状态选择标准 Slot-1 装载或 Slot-2 回退。

    mov r0, #1
    ldr r5, [p2_slot_primary_p1_command]
    strh r0, [r5]
    mov r1, #0
    mov r2, #1
    bl p2_write_power_management
    mov r1, #0x3d
    mov r2, #0
    bl p2_write_power_management

    ldr r0, [p2_slot_firmware_bytes]
    ldr r4, [p2_slot_header_ram]
    mov r1, r4
    ldr r2, [p2_slot_header_size]
    bl p2_read_firmware

    ldr r0, [p2_slot_primary_header_compare]
    ldrh r1, [r0]
    ldr r0, [p2_slot_secondary_header_compare]
    ldrh r2, [r0]
    cmp r2, r1
    mov r1, r4
    mov r2, #0x20
    bls p2_skip_header_fast_copy
    swi 0x0c

p2_skip_header_fast_copy:
    bl p2_signal_boot_finish

    ldr r1, [p2_slot_spi_first_control]
    mov r0, #0x84
    bl p2_spi_write
    ldr r1, [p2_slot_spi_second_control]
    mov r0, #0
    bl p2_spi_write
    bl p2_clear_dma

    ldr r0, [p2_slot_powercnt]
    mov r1, #1
    strh r1, [r0]
    ldr r1, [p2_slot_delay_units]
    swi 0x08

; Do not read the chosen media until P1 clears the mailbox after cold preparation.
; 在 P1 冷启动准备后清零邮箱前，不读取所选媒体。
p2_wait_p1:
    ldrh r0, [r5]
    cmp r0, #0
    bne p2_wait_p1

    ldr r4, [p2_slot_recovery_state]
    ldr r0, [r4, #0x0c]
    cmp r0, #0
    bne p2_boot_slot2

    ldr r4, [p2_slot_card_transfer_context]
    mov r0, #1
    lsl r0, r0, #15
    ldr r3, [r4, #0x20]
    sub r3, r0, r3
    ldr r1, [r4, #0x28]
    add r1, r1, r3
    ldr r2, [r4, #0x2c]
    sub r2, r2, r3
    bl p2_card_transfer

    ldr r0, [r4, #0x30]
    ldr r1, [r4, #0x38]
    ldr r2, [r4, #0x3c]
    bl p2_card_transfer

    ldr r0, [p2_slot_recovery_copy_source]
    ldr r1, [p2_slot_recovery_copy_destination]
    mov r2, #6
    swi 0x0c
    bl p2_clear_dma
    ldr r0, [r4, #0x24]
    ldr r1, [r4, #0x34]
    str r0, [r5]
    bx r1

; Nonzero recovery state uses the established Slot-2 trampoline instead of standard Slot-1 B7 reads.
; 非零恢复状态使用既有 Slot-2 跳板，而非标准 Slot-1 B7 读取。
p2_boot_slot2:

    ldmia r7!, {r0-r4}
    stmia r3!, {r0-r2}
    str r0, [r4, #4]
    add r6, #0x14
    b p2_handoff

    .org PrimaryP2RamAddress + 0x000000ce
; Build B7 requests from one header section: ROM offset, RAM destination, remaining byte count, then repeat by chunk.
; 用一个头部段构造 B7 请求：ROM 偏移、RAM 目标、剩余字节数，再按块重复。
p2_card_transfer:
    ; Standard B7 card reads load ARM9/ARM7 from the already available NDS header fields.
    ; 标准 B7 读卡根据已存在的 NDS 头字段装载 ARM9/ARM7。
    push {r4-r7, lr}
    mov r7, #1
    lsl r7, r7, #9
    ldr r3, [r4, #0x60]
    ldr r5, [p2_slot_card_read_command_base]
    orr r5, r3
    mov r6, #0xb7
    lsl r6, r6, #24
    lsr r0, r0, #8
    orr r6, r0
    mov r4, r2

p2_card_transfer_loop:
    mov r0, r5
    mov r2, r7
    cmp r4, r7
    bhi p2_card_transfer_chunk_ready
    mov r2, r4

p2_card_transfer_chunk_ready:
    mov r3, r6
    bl p2_card_read_chunk
    add r6, #2
    sub r4, r4, r7
    bhi p2_card_transfer_loop
    pop {r4-r7, pc}

    .org PrimaryP2RamAddress + 0x000000fc
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
p2_arm9_trampoline_target:
    .dw NdsCartHeaderRetailArm9EntryAddress
p2_arm9_trampoline_primary_p1:
    .dw PrimaryP1RamAddress

    .org PrimaryP2RamAddress + 0x00000128
p2_load_secondary_p12:
    mov r1, r11
    mov r2, #0x40
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
    str r7, [r4, #4]

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
    adr r3, p2_legacy_pool
    push {r1}
    bx r5

    .org PrimaryP2RamAddress + 0x00000172
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

    .org PrimaryP2RamAddress + 0x00000190
p2_spi_wait_transfer:
    ldr r1, [p2_slot_spicnt]

p2_spi_wait_transfer_busy:
    ldrh r0, [r1]
    lsr r0, r0, #8
    bcs p2_spi_wait_transfer_busy
    ldrb r0, [r1, #2]
    strh r0, [r1, #2]
    bx lr

    .org PrimaryP2RamAddress + 0x000001a0
p2_legacy_pool:
    .dw p2_firmware_read_callback + 1, Bios7SpiTransferFinish, p2_spi_wait_transfer + 1

p2_write_power_management:
    ldr r3, [p2_slot_bios_power_management_write]
    mov r0, #0
    bx r3

p2_clear_dma:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [p2_slot_dma0_sad]

p2_clear_dma_loop:
    str r0, [r1, r2]
    sub r2, r2, #4
    bpl p2_clear_dma_loop
    bx lr

p2_read_firmware:
    ldr r3, [p2_slot_bios_firmware_read]
    bx r3

p2_signal_boot_finish:
    ldr r3, [p2_slot_bios_signal_boot_finish]
    bx r3

p2_spi_write:
    ldr r3, [p2_slot_spicnt]

p2_spi_wait:
    ldrh r2, [r3]
    lsr r2, r2, #8
    bcs p2_spi_wait
    strh r1, [r3]
    strh r0, [r3, #2]

p2_spi_wait_read:
    ldrh r2, [r3]
    lsr r2, r2, #8
    bcs p2_spi_wait_read
    ldrh r1, [r3, #2]
    bx lr

p2_write_card_command:
    strb r3, [r4, #7]
    lsr r3, r3, #8
    strb r3, [r4, #6]
    lsr r3, r3, #8
    strb r3, [r4, #5]
    lsr r3, r3, #8
    strb r3, [r4, #4]
    lsr r3, r3, #8
    str r3, [r4, #8]
    bx lr

p2_card_read_chunk:
    push {r4, r5, lr}
    ldr r4, [p2_slot_card_control]
    ldr r5, [p2_slot_gc_data_in]
    bl p2_write_card_command
    str r0, [r4]

p2_card_read_wait:
    ldr r0, [r4]
    lsl r0, r0, #9
    bcc p2_card_read_skip
    ldr r0, [r5]
    sub r2, #4
    bmi p2_card_read_skip
    str r0, [r1]
    add r1, #4

p2_card_read_skip:
    ldr r0, [r4]
    lsl r0, r0, #1
    bcs p2_card_read_wait
    pop {r4, r5, pc}

    .org PrimaryP2RamAddress + 0x00000218
p2_slot_primary_p1_command:
    .dw PrimaryP1RamAddress + 4
p2_slot_firmware_bytes:
    .dw FirmwareUserSettingsAddress256K
p2_slot_header_ram:
    .dw FirmwareUserSettingsRamAddress
p2_slot_header_size:
    .dw 0x00000180
p2_slot_primary_header_compare:
    .dw 0x023ffcf0
p2_slot_secondary_header_compare:
    .dw 0x023ffdf0
p2_slot_spi_first_control:
    .dw 0x00008a00
p2_slot_spi_second_control:
    .dw 0x00008200
p2_slot_powercnt:
    .dw REG_POWERCNT
p2_slot_delay_units:
    .dw 0x00000400
p2_slot_recovery_state:
    .dw 0x027ff800
p2_slot_card_transfer_context:
    .dw 0x027ffe00
p2_slot_recovery_copy_source:
    .dw 0x023ff800
p2_slot_recovery_copy_destination:
    .dw 0x023ffc00
p2_slot_card_read_command_base:
    .dw 0xa1000000
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
p2_slot_bios_power_management_write:
    .dw Bios7PowerManagementWrite
p2_slot_dma0_sad:
    .dw REG_DMA0SAD
p2_slot_bios_firmware_read:
    .dw Bios7FirmwareRead
p2_slot_bios_signal_boot_finish:
    .dw Bios7SignalBootFinish
p2_slot_card_control:
    .dw REG_ROMCTRL
p2_slot_gc_data_in:
    .dw REG_GCDATAIN
.close

; Detailed analysis / 详细分析:
; 1. Start+Select or BOOT enters p2_recovery_boot. P2 first writes mailbox value 1 and waits for P1 to acknowledge cleanup.
; 2. It refreshes the working header and consults 0x027FF80C + 0x0C. Nonzero chooses the old Slot-2 handoff.
; 3. Zero invokes p2_card_transfer twice: B7 reads use resident-header ARM9/ARM7 ROM offset, RAM destination, size, and entry fields.
; 4. After copying the required handoff values, P2 writes ARM9's entry to the mailbox and branches to ARM7's entry.
; 1. Start+Select 或 BOOT 进入 p2_recovery_boot。P2 先写邮箱值 1，并等待 P1 确认清理。
; 2. 它刷新工作头并检查 0x027FF80C + 0x0C；非零选择旧 Slot-2 交接。
; 3. 零会两次调用 p2_card_transfer：B7 读取使用驻留头的 ARM9/ARM7 ROM 偏移、RAM 目标、大小和入口字段。
; 4. 复制所需交接值后，P2 将 ARM9 入口写入邮箱并跳至 ARM7 入口。
