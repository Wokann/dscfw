
.create "build/fp1.bin", 0
    .headersize FlashMeFp1RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    ldr r10, [fp1_context_ipc_sync]

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    subs r0, r0, #0x0b
    bmi fp1_wait_b
    bne fp1_cold_boot

    .if BuildStealth

    ldr lr, [fp1_slot_arm9_return]
    ldr lr, [lr]
    b fp1_retail
    .else
    ldr r0, [fp1_slot_powercnt]
    ldr r1, [fp1_slot_arm9_boot_state]
    strh r1, [r0]

fp1_wait_d_warm:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    cmp r0, #0x0d
    bne fp1_wait_d_warm
    ldr lr, [fp1_slot_arm9_return]
    ldr lr, [lr]
    b fp1_retail
    .endif

fp1_cold_boot:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp1_slot_dma0_src]

fp1_clear_dma_range:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_dma_range
    ldr r1, [fp1_slot_powercnt]
    mov r0, #0
    strh r0, [r1]

    ldr r4, [fp1_slot_vram_a_cr]
    ldr r5, [fp1_slot_vram_lcdc_enable_abcd]
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]

    mov r1, #VRAM_A
    mov r2, #VramLcdcBytes
    bl fp1_zero_range

    mov r5, #(WRAM_0KARM9_32KARM7 << 24)
    strh r5, [r4]
    strh r5, [r4, #2]
    str r5, [r4, #4]
    strh r5, [r4, #8]

fp1_wait_d_cold:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    cmp r0, #0x0d
    bne fp1_wait_d_cold
    ldr r0, [fp1_slot_powercnt]
    ldr r1, [fp1_slot_arm9_boot_state]
    strh r1, [r0]
    mov r1, #OAM
    mov r2, #MM_OBJRAM_SZ
    bl fp1_zero_range
    mov r1, #BG_PALETTE
    mov r2, #MM_PALRAM_SZ
    bl fp1_zero_range
    adr r12, fp1_context
    ldmia r12, {r0-r11}
    stmia r11, {r4-r7}
    bx r4

fp1_zero_range:
    mov r0, #0

fp1_zero_loop:
    strh r0, [r1], #2
    strh r0, [r1], #2
    strh r0, [r1], #2
    strh r0, [r1], #2
    subs r2, r2, #8
    bne fp1_zero_loop
    mov pc, lr

    .org FlashMeFp1RamAddress + Fp1ContextOffset
fp1_context:

fp1_context_r0:
    .dw Fp1ContextR0
fp1_context_r1:
    .dw Fp1ContextR1
fp1_context_r2:
    .dw Fp1ContextR2
fp1_context_r3:
    .dw Fp1ContextR3
fp1_context_r4:
    .dw Arm9ReturnSlotNext

    .headersize Arm9ReturnSlot - orga(fp1_context_r4)
    .org Arm9ReturnSlot
fp1_runtime_loop_slot:
    .org Arm9ReturnSlot + 4
fp1_context_r5:
    strh r10, [r9]
fp1_context_r6:
    ldr r0, [fp1_runtime_loop_slot]
fp1_context_r7:
    bx r0
    .headersize FlashMeFp1RamAddress
fp1_context_r8:
    .dw Fp1ContextR8
fp1_context_ipc_sync:
    .dw REG_IPC_SYNC
fp1_context_r10:
    .dw Fp1ContextR10
fp1_context_r11:
    .dw Arm9ReturnSlot

    .if BuildStealth
fp1_slot_arm9_return:
    .dw Arm9ReturnSlot
fp1_slot_dma0_src:
    .dw REG_DMA0SAD
fp1_slot_powercnt:
    .dw REG_POWERCNT
    .else
fp1_slot_powercnt:
    .dw REG_POWERCNT
fp1_slot_arm9_boot_state:
    .dw Arm9BootState
fp1_slot_arm9_return:
    .dw Arm9ReturnSlot
fp1_slot_dma0_src:
    .dw REG_DMA0SAD
    .endif
fp1_slot_vram_a_cr:
    .dw VRAM_A_CR
fp1_slot_vram_lcdc_enable_abcd:
    .dw VramLcdcEnableAbcd
    .if BuildStealth
fp1_slot_arm9_boot_state:
    .dw Arm9BootState
    .endif
    .endarea

fp1_retail:
    .org RetailP1RamAddress

    .incbin "temp/p1.bin"

    .if !BuildStealth

    .org RetailP1RamAddress + 0x2dc
    .thumb
    lsl r3, r4, #0

    .org RetailP1RamAddress + 0x89e
    .thumb
    cmp r1, #1

    .org RetailP1RamAddress + 0x8ba
    .thumb
    cmp r0, #1

    .org RetailP1RamAddress + 0x8ce
    .thumb
    lsl r0, r0, #0
    .endif

    .org RetailP1RamAddress + 0x6de6
    .thumb
    .dh 0x0000

    .org RetailP1RamAddress + 0x6e3c
    .thumb
    .dh 0x0000
.close
