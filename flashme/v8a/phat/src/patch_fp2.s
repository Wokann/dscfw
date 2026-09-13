.create "build/fp2.bin", 0
    .headersize FlashMeFp2RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    mov r0, #8
    ldr r0, [fp2_slot_powercnt]
    mov r1, #1
    strh r1, [r0]
    mov r1, #0x3000
    swi SwiSoundBias
    bl fp2_clear_dma
    ldr r10, [fp2_slot_keyinput]
    ldrh r0, [r10]

    .if BuildNoAuto
        ; V8a noauto changes the manual FlashMe selector from A+B+X+Y to Select.
        ; V8a noauto 将手动 FlashMe 选择键从 A+B+X+Y 改为 Select。

        tst r0, #KEY_SELECT
        bne fp2_retail_boot
        b fp2_flash_boot

fp2_retained_boot_state_check:
        adr r0, fp2_boot_state
        ldmia r0, {r1-r4}
        ldmia r1, {r6-r9}
        cmp r9, r4
        beq fp2_flash_boot
        cmp r6, r2
        bne fp2_retail_boot
        cmp r7, r3
        beq fp2_flash_boot
    .else

        tst r0, #KEY_SELECT
        beq fp2_retail_boot
        ands r0, r0, #(KEY_A | KEY_B)
        bne fp2_check_boot_state
        ldrh r0, [r10, #(REG_KEYXY - REG_KEYINPUT)]
        ands r0, r0, #(KEYXY_X | KEYXY_Y)
        beq fp2_flash_boot

; This selector checks keys and retained Slot-2 state; noauto makes Select the manual FlashMe key. See after .close.
; 此选择器检查按键和保留 Slot-2 状态；noauto 将 Select 作为手动 FlashMe 键。详见 .close 后。
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
    .endif

    .org FlashMeFp2RamAddress + (0x064 - (BuildNoAuto * 0x10))
; Retained path: publish ARM7 state for Nintendo P2, optionally present the normal fade, then return to retained code.
; 保留路径：为任天堂 P2 发布 ARM7 状态，可选呈现 normal 渐变，再返回保留代码。
fp2_retail_boot:
    mov r0, #0x0b00
    strh r0, [r10, #0x50]
    bl fp2_header_copy
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
        mov r0, #0x0e00
        strh r0, [r10, #0x50]
        ldr lr, [fp2_slot_arm9_return]
        ldr lr, [lr]
        b fp2_retail_boot_code

; One PWM step writes a power-management channel after a delay; the caller repeats it from black to white.
; 单个 PWM 步骤延时后写入电源管理通道；调用者重复它以从黑渐变到白。
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

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x07c : 0x0e0) - (BuildNoAuto * 0x10))
fp2_boot_state:
    .dw GbaRomTitleAddress
    .ascii "DSBooterPASS"

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x08c : 0x0f0) - (BuildNoAuto * 0x10))
; FlashMe path: stop the retained path, then perform cold program setup before entering the selected ARM7 entry.
; FlashMe 路径：停止保留路径，随后进行冷启动程序准备并进入所选 ARM7 入口。
fp2_flash_boot:
    mov r0, #0x0c00
    strh r0, [r10, #0x50]
    bl fp2_cold_boot
    ldr r12, [fp2_slot_arm7_return]
    bx r12

; Copy the working header and reset DMA; the remaining operations make ARM7 state safe for program entry.
; 复制工作头并重置 DMA；其余操作使 ARM7 状态适合进入程序。
fp2_cold_boot:
    mov r11, lr
    bl fp2_clear_dma
    bl fp2_header_copy
    bl fp2_signal_boot_finish
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

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x0e4 : 0x148) - (BuildNoAuto * 0x10))
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

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x18c : 0x1f0) - (BuildNoAuto * 0x10))
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

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x1cc : 0x230) - (BuildNoAuto * 0x10))
fp2_clear_dma:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp2_slot_dma0_sad]
fp2_clear_dma_loop:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp2_clear_dma_loop
    bx lr

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x1e8 : 0x24c) - (BuildNoAuto * 0x10))
fp2_header_copy:
    stmdb sp!, {lr}
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
    ldmia sp!, {pc}

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x220 : 0x284) - (BuildNoAuto * 0x10))
fp2_read_firmware:
    ldr r3, [fp2_slot_bios_copy]
    bx r3

fp2_write_power_management:
    ldr r3, [fp2_slot_bios_ipc_send]
    bx r3

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x230 : 0x294) - (BuildNoAuto * 0x10))
fp2_signal_boot_finish:
    ldr r3, [fp2_slot_bios_boot_return]
    bx r3

    .org FlashMeFp2RamAddress + ((BuildStealth ? 0x23c : 0x2a0) - (BuildNoAuto * 0x10))
fp2_slot_powercnt:
    .dw REG_POWERCNT
fp2_slot_keyinput:
    .dw REG_KEYINPUT
fp2_slot_arm9_return:
    .dw NdsCartHeaderArm7EntryAddress
fp2_slot_arm7_return:
    .dw GbaArm7Entry
fp2_slot_aux_spi_control:
    .dw 0x0000a040
fp2_slot_aux_spicnt:
    .dw REG_AUXSPICNT
fp2_slot_dma0_sad:
    .dw REG_DMA0SAD
fp2_slot_gc_data_in:
    .dw REG_GCDATAIN
fp2_slot_dma_card_control:
    .dw 0xaf000001
fp2_slot_phat_spi_initial:
    .dw 0x00008802
fp2_slot_phat_spi_followup:
    .dw 0x00008002
fp2_slot_spicnt:
    .dw REG_SPICNT
fp2_slot_firmware_bytes:
    .dw FirmwareUserSettingsAddress256K
fp2_slot_header_ram:
    .dw FirmwareUserSettingsRamAddress
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
.close

; Detailed analysis / 详细分析:
; 1. `fp2_check_boot_state` evaluates active-low keys and the Slot-2 title/signature. Select keeps retained firmware;
;    A+B+X+Y forces FlashMe; `PASS`/`DSBooter` provides the automatic selection.
; 2. `fp2_retail_boot` returns to Nintendo P2. normal builds visit the PWM fade helper; stealth skips that presentation.
; 3. `fp2_flash_boot` takes the FlashMe path. `fp2_cold_boot` reads the working header, clears DMA, signals boot completion,
;    performs the required SPI/IPC transition, waits for the peer state, and then branches to the ARM7 entry.
; 1. `fp2_check_boot_state` 判断低有效按键和 Slot-2 标题/标识。Select 保留固件；A+B+X+Y 强制 FlashMe；
;    `PASS`/`DSBooter` 提供自动选择。
; 2. `fp2_retail_boot` 回到任天堂 P2。normal 进入 PWM 渐变辅助例程；stealth 跳过该呈现步骤。
; 3. `fp2_flash_boot` 走 FlashMe 路径。`fp2_cold_boot` 读取工作头、清 DMA、通知启动完成、执行所需 SPI/IPC 切换，
;    等待对端状态后跳转 ARM7 入口。
