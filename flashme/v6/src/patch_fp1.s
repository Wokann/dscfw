.create "build/fp1.bin", 0
    .headersize FlashMeFp1RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    ldr r10, [fp1_context_ipc_sync]

; IPC B resumes the warm retained path; the other accepted state runs cold setup before ARM9 handoff. See after .close.
; IPC B 恢复热启动保留路径；另一已接受状态在 ARM9 交接前执行冷启动准备。详见 .close 后。
fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    subs r0, r0, #0x0b
    bmi fp1_wait_b
    bne fp1_cold_boot

    .if BuildStealth

    ldr lr, [fp1_slot_arm9_return]
    ldr lr, [lr]
    b fp1_retail_boot
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
    b fp1_retail_boot
    .endif

; IPC did not select warm continuation: reset DMA/display state before either CPU enters its program path.
; IPC 未选择热启动后续：在任一 CPU 进入程序路径前重置 DMA/显示状态。
fp1_cold_boot:

    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp1_slot_dma0_src]

fp1_clear_dma_range:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_dma_range

    mov r0, #1
    swi SwiCustomPost
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

    mov r3, #FirmwarePart1RamaddrEncodingBase
    ldrb r0, [r3, #-4]
    cmp r0, #0
    beq fp1_wait_d_cold
    sub r1, r3, #0x200
    mov r2, #0x170
    bl fp1_zero_range
    ldr r0, [fp1_slot_clear_source]
    sub r1, r3, #0x140
    mov r2, #0x28
    swi SwiCpuFastSet

; Cold ARM9 setup is complete; wait until ARM7 publishes IPC state D before restoring ARM9 context.
; ARM9 冷启动准备完成；等待 ARM7 发布 IPC 状态 D 后恢复 ARM9 上下文。
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
    ldmia r12, {r4-r9}
    stmia r4, {r5,r6}
    str r4, [r9]
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

    .if BuildStealth
        .org FlashMeFp1RamAddress + 0x11c
    .else
        .org FlashMeFp1RamAddress + 0x138
    .endif
fp1_context:

fp1_context_r4:
    .dw FlashMeArm9ReturnTrampolineAddress

    .headersize FlashMeArm9ReturnTrampolineAddress - orga(fp1_context_r4)
    .org FlashMeArm9ReturnTrampolineAddress
fp1_runtime_trampoline_entry:
    .org FlashMeArm9ReturnTrampolineAddress + 4
fp1_context_r5:
    strh r8, [r7]
fp1_context_r6:
    ldr pc, [r9]
    .headersize FlashMeFp1RamAddress
fp1_context_ipc_sync:
    .dw REG_IPC_SYNC
fp1_context_ipc_phase_d:
    .dw 0x00000d00
fp1_context_arm9_return:
    .dw NdsCartHeaderArm9EntryAddress

    .if BuildStealth
fp1_slot_arm9_return:
    .dw NdsCartHeaderArm9EntryAddress
fp1_slot_dma0_src:
    .dw REG_DMA0SAD
fp1_slot_powercnt:
    .dw REG_POWERCNT
    .else
fp1_slot_powercnt:
    .dw REG_POWERCNT
fp1_slot_arm9_boot_state:
    .dw Arm9PowerControlValue
fp1_slot_arm9_return:
    .dw NdsCartHeaderArm9EntryAddress
fp1_slot_dma0_src:
    .dw REG_DMA0SAD
    .endif
fp1_slot_vram_a_cr:
    .dw VRAM_A_CR
fp1_slot_vram_lcdc_enable_abcd:
    .dw VramcntLcdcEnableAbcd
fp1_slot_clear_source:
    .dw Bios9NintendoLogoAddress
    .if BuildStealth
fp1_slot_arm9_boot_state:
    .dw Arm9PowerControlValue
    .endif
    .endarea

; Embed retained P1 here; the following fixed offsets alter only the listed retained-P1 decisions.
; 此处嵌入保留 P1；后续固定偏移仅改变所列保留 P1 判断。
fp1_retail_boot:
    .org RetailP1RamAddress

    .incbin "temp/p1.bin"

    .if !BuildStealth

    .org BootStateDispatch
    .thumb
    lsl r3, r4, #0

    .org BootDisplayFade_1
    .thumb
    cmp r1, #1

    .org BootDisplayFade_2
    .thumb
    cmp r0, #1

    .org BootDisplayFade_3
    .thumb
    lsl r0, r0, #0
    .endif

    .org P3P4Crc16Gate + 0x3a
    .thumb
    .dh 0x0000

    .org P5Crc16Gate + 0x20
    .thumb
    .dh 0x0000
.close

; Detailed analysis / 详细分析:
; 1. `fp1_wait_b` polls the low nibble of IPC_SYNC. State B is the warm continuation handshake.
; 2. `fp1_cold_boot` is the alternate path: it clears DMA controls, display/VRAM state, and later OAM/palette memory.
; 3. Both paths wait for ARM7 state D before restoring the saved register context and entering ARM9 continuation code.
; 4. `fp1_retail_boot` embeds retained P1 and applies version-specific word/halfword patches after the embedded bytes.
; 1. `fp1_wait_b` 轮询 IPC_SYNC 低半字节；状态 B 是热启动后续握手。
; 2. `fp1_cold_boot` 是替代路径：清除 DMA 控制、显示/VRAM 状态，并随后清除 OAM/调色板内存。
; 3. 两条路径都等待 ARM7 的 D 状态，再恢复保存的寄存器上下文并进入 ARM9 后续代码。
; 4. `fp1_retail_boot` 嵌入保留 P1，并在嵌入字节之后应用版本专属的字/半字补丁。

; Additional version-specific analysis / 附加版本专属分析:
; Version-specific V6 flow / V6 版本专属流程:
; After the generic cold cleanup, this FP1 conditionally refreshes the header/Logo work area and returns through a relocated trampoline.
; The code establishes initialization order; no separate user-visible screen change is confirmed.
; 在通用冷启动清理之后，此 FP1 按条件刷新头部/Logo 工作区，并经迁移后的跳板返回。
; 代码确定初始化顺序；尚未确认独立的用户可见画面变化。
