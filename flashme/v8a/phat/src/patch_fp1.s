; FlashMe boot9 / FP1: ARM9 secondary boot component.
; FlashMe boot9 / FP1：ARM9 次级启动组件。

.create "build/fp1.bin", 0
    .headersize FlashMeFp1RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    ldr r10, [fp1_context_ipc_sync]

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    cmp r0, #0x0b
    bcc fp1_wait_b
    beq fp1_warm_boot
    cmp r0, #0x0c
    beq fp1_cold_boot
    bl fp1_cold_prepare
    ldr lr, [fp1_slot_arm9_unknown_return]
    ldr lr, [lr]
    bx lr

fp1_warm_boot:
    .if BuildStealth

        ldr lr, [fp1_slot_arm9_return]
        ldr lr, [lr]
        b fp1_retail_boot
    .else

        ldr r0, [fp1_slot_powercnt]
        ldr r1, [fp1_slot_arm9_boot_state]
        strh r1, [r0]

fp1_wait_e_warm:
        ldrh r0, [r10]
        and r0, r0, #0x0f
        cmp r0, #0x0e
        bne fp1_wait_e_warm
        ldr lr, [fp1_slot_arm9_return]
        ldr lr, [lr]
        b fp1_retail_boot
    .endif

    .if BuildStealth
        .org FlashMeFp1RamAddress + 0x03c
    .else
        .org FlashMeFp1RamAddress + 0x058
    .endif
fp1_cold_boot:
    bl fp1_cold_prepare
    adr r12, fp1_context
    ldmia r12, {r4-r9}
    stmia r4, {r5,r6}
    str r4, [r9]
    bx r4

    .org FlashMeFp1RamAddress + (BuildStealth ? 0x054 : 0x070)
fp1_context:
fp1_context_r4:
    .dw FlashMeArm9ReturnTrampolineAddress

    .headersize FlashMeArm9ReturnTrampolineAddress - orga(fp1_context_r4)
    .org FlashMeArm9ReturnTrampolineAddress
fp1_runtime_trampoline_entry:
    .org FlashMeArm9ReturnTrampolineAddress + 4
fp1_context_r5:
    mov r0, r0
fp1_context_r6:
    ldr pc, [r9]
    .headersize FlashMeFp1RamAddress
fp1_context_ipc_sync:
    .dw REG_IPC_SYNC
fp1_context_ipc_phase_e:
    .dw 0x00000e00
fp1_context_arm9_return:
    .dw NdsCartHeaderArm9EntryAddress

    .org FlashMeFp1RamAddress + (BuildStealth ? 0x06c : 0x088)
fp1_cold_prepare:
    mov r11, lr
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp1_slot_dma0_sad]

fp1_clear_dma:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_dma

    mov r0, #1
    swi SwiCustomPost
    ldr r1, [fp1_slot_powercnt]
    mov r0, #0
    strh r0, [r1]

    ldr r4, [fp1_slot_vram_a_cr]
    ldr r5, [fp1_slot_vram_lcdc_disable_all]
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

    mov r3, #FirmwarePart1RamaddrEncodingBase
    ldrb r0, [r3, #-4]
    cmp r0, #0
    beq fp1_wait_e_cold
    sub r1, r3, #0x200
    mov r2, #0x170
    bl fp1_zero_range
    ldr r0, [fp1_slot_clear_source]
    sub r1, r3, #0x140
    mov r2, #0x28
    swi SwiCpuFastSet

fp1_wait_e_cold:
    ldr r0, [fp1_slot_powercnt]
    ldr r1, [fp1_slot_arm9_boot_state]
    strh r1, [r0]
    mov r1, #OAM
    mov r2, #MM_OBJRAM_SZ
    bl fp1_zero_range
    mov r1, #BG_PALETTE
    mov r2, #MM_PALRAM_SZ
    bl fp1_zero_range

    mov r0, #0x04000000
    mov r1, #0
    str r1, [r0]
    add r0, r0, #0x1000
    str r1, [r0]
    mov r0, #0x0e00
    strh r0, [r10]
    bx r11

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

    .org FlashMeFp1RamAddress + (BuildStealth ? 0x164 : 0x180)
    .if BuildStealth
fp1_slot_arm9_unknown_return:
    .dw FlashMeArm9FallbackReturnPointerAddress
fp1_slot_arm9_return:
    .dw NdsCartHeaderArm9EntryAddress
fp1_slot_dma0_sad:
    .dw REG_DMA0SAD
fp1_slot_powercnt:
    .dw REG_POWERCNT
fp1_slot_vram_a_cr:
    .dw VRAM_A_CR
fp1_slot_vram_lcdc_disable_all:
    .dw VramcntLcdcEnableAbcd
fp1_slot_clear_source:
    .dw Bios9NintendoLogoAddress
fp1_slot_arm9_boot_state:
    .dw Arm9PowerControlValue
    .else
fp1_slot_arm9_unknown_return:
    .dw FlashMeArm9FallbackReturnPointerAddress
fp1_slot_powercnt:
    .dw REG_POWERCNT
fp1_slot_arm9_boot_state:
    .dw Arm9PowerControlValue
fp1_slot_arm9_return:
    .dw NdsCartHeaderArm9EntryAddress
fp1_slot_dma0_sad:
    .dw REG_DMA0SAD
fp1_slot_vram_a_cr:
    .dw VRAM_A_CR
fp1_slot_vram_lcdc_disable_all:
    .dw VramcntLcdcEnableAbcd
fp1_slot_clear_source:
    .dw Bios9NintendoLogoAddress
    .endif
    .endarea

fp1_retail_boot:
    .org RetailP1RamAddress

    .incbin "temp/p1.bin"

    .if !BuildStealth

        .org RetailP1RamAddress + 0x02dc
        .thumb
        lsl r3, r4, #0

        .org RetailP1RamAddress + 0x089e
        .thumb
        cmp r1, #1

        .org RetailP1RamAddress + 0x08ba
        .thumb
        cmp r0, #1

        .org RetailP1RamAddress + 0x08ce
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
