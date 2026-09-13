.create "build/p1.bin", 0
    .headersize PrimaryP1RamAddress
    .area 0x000000fc, 0x00
    .arm

    b p1_wait_command
; 0 waits; 1 performs ARM9 cold setup; any other nonzero word is the final ARM9 entry. See after .close.
; 0 等待；1 执行 ARM9 冷启动准备；其他非零字为最终 ARM9 入口。详见 .close 后。
p1_command:
    .dw 0x00000000

; Poll the P2 mailbox until it asks for cleanup or supplies a final ARM9 entry.
; 轮询 P2 邮箱，直到它请求清理或提供最终 ARM9 入口。
p1_wait_command:
    ldr r0, [p1_command]
    cmp r0, #0
    beq p1_wait_command
    cmp r0, #1
    beq p1_cold_boot
    bx r0

; Mailbox value 1: clear ARM9-visible hardware state, then acknowledge by clearing the mailbox.
; 邮箱值 1：清理 ARM9 可见硬件状态，再清零邮箱以确认。
p1_cold_boot:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [p1_slot_dma0_sad]

p1_clear_dma:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl p1_clear_dma

    mov r0, #1
    swi 0x1f0000
    ldr r1, [p1_slot_powercnt]
    mov r0, #0
    strh r0, [r1]

    ldr r4, [p1_slot_vram_a_cr]
    ldr r5, [p1_slot_vram_lcdc_disable_all]
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    mov r1, #VRAM_A
    mov r2, #VramLcdcBytes
    bl p1_zero_halfwords
    mov r5, #(WRAM_0KARM9_32KARM7 << 24)
    strh r5, [r4]
    strh r5, [r4, #2]
    str r5, [r4, #4]
    strh r5, [r4, #8]

    ldr r0, [p1_slot_powercnt]
    ldr r1, [p1_slot_arm9_boot_state]
    strh r1, [r0]
    mov r1, #OAM
    mov r2, #MM_OBJRAM_SZ
    bl p1_zero_halfwords
    mov r1, #BG_PALETTE
    mov r2, #MM_PALRAM_SZ
    bl p1_zero_halfwords

    mov r0, #0x04000000
    mov r1, #0
    str r1, [r0]
    add r0, r0, #0x1000
    str r1, [r0]
    mov r0, #0
    str r0, [p1_command]
    b p1_wait_command

p1_zero_halfwords:
    mov r0, #0
p1_zero_loop:
    strh r0, [r1], #2
    strh r0, [r1], #2
    strh r0, [r1], #2
    strh r0, [r1], #2
    subs r2, r2, #8
    bne p1_zero_loop
    mov pc, lr

    .org PrimaryP1RamAddress + 0x000000e8
p1_slot_dma0_sad:
    .dw REG_DMA0SAD
p1_slot_powercnt:
    .dw REG_POWERCNT
p1_slot_vram_a_cr:
    .dw VRAM_A_CR
p1_slot_vram_lcdc_disable_all:
    .dw VramcntLcdcEnableAbcd
p1_slot_arm9_boot_state:
    .dw Arm9PowerControlValue
    .endarea
.close

; Detailed analysis / 详细分析:
; 1. `p1_wait_command` polls the mailbox. Zero means wait; one selects `p1_cold_boot`; another value is an ARM9 entry address.
; 2. Cold boot clears DMA/video memory state and returns the mailbox to zero, acknowledging that P2 may continue.
; 3. P2 finally writes the chosen ARM9 entry to the same mailbox, and P1 branches to it.
; 1. `p1_wait_command` 轮询邮箱：零表示等待；一选择 `p1_cold_boot`；其他值为 ARM9 入口地址。
; 2. 冷启动清除 DMA/视频内存状态并将邮箱归零，确认 P2 可以继续。
; 3. P2 最后向同一邮箱写入所选 ARM9 入口，P1 跳转至该入口。
