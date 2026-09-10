// Stage 2 ARM9 half for FlashMe V7 New Phat.
//
// Primary P2 has already selected FH and loaded the FP pair.  This file emits
// the 0x400-byte FlashMe prefix followed by the retained official V3 P1 body.
// The body begins at its original decoded RAM entry, so it keeps every absolute
// address used by the retail program.
// 一级 P2 已选择 FH 并加载 FP 组件对。本文件生成 0x400 字节的 FlashMe 前置代码，
// 随后直接接入保留的官方 V3 P1 主体。该主体从原始解码后的 RAM 入口开始，因此可以
// 保持零售程序使用的所有绝对地址。
.create "build/fp1.bin", 0
    .headersize FlashMeFp1RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm

    // IPC_SYNC is stored inside the variant-specific hand-off context.  The
    // direct PC-relative load intentionally preserves the historical layout.
    // IPC_SYNC 存在于按变体区分的交接上下文中。此处直接使用 PC 相对读取，以保留历史布局。
    ldr r10, [pc, #Fp1ContextOffset + 4]

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    cmp r0, #0x0b
    bcc fp1_wait_b
    beq fp1_warm_boot
    cmp r0, #0x0c
    beq fp1_cold_boot

    // An inherited unexpected phase runs the same preparation and then uses
    // the historical continuation slot at 0x02100024.
    // 继承路径中遇到意外阶段时会执行同样的准备，并使用历史续接槽 0x02100024。
    bl fp1_cold_prepare
    ldr lr, =Arm9UnknownReturnSlot
    ldr lr, [lr]
    bx lr

fp1_warm_boot:
    .if BuildStealth
        // Stealth B route returns to retail ARM9 immediately.
        // Stealth 的 B 路径立即回到零售 ARM9。
        ldr lr, =Arm9ReturnSlot
        ldr lr, [lr]
        b fp1_retail
    .else
        // The normal B route waits until FP2 has completed its service work
        // and published phase E.
        // 常规版 B 路径等待 FP2 完成服务工作并发布 E 阶段。
        ldr r0, =REG_POWERCNT
        ldr r1, =Arm9BootState
        strh r1, [r0]

fp1_wait_e_warm:
        ldrh r0, [r10]
        and r0, r0, #0x0f
        cmp r0, #0x0e
        bne fp1_wait_e_warm
        ldr lr, =Arm9ReturnSlot
        ldr lr, [lr]
        b fp1_retail
    .endif

    .if BuildStealth
        .orga 0x03c
    .else
        .orga 0x058
    .endif
fp1_cold_boot:
    bl fp1_cold_prepare
    adr r12, fp1_context
    ldmia r12, {r4-r9}
    stmia r4, {r5,r6}
    str r4, [r9]
    bx r4

    // The context is consumed by the C route.  It writes an ARM9 trampoline
    // at 0x027fff70 which resumes the retained ARM9 continuation after FP1
    // has published phase E.
    // C 路径会消费这份上下文：它在 0x027fff70 写入 ARM9 跳板，并在 FP1 发布 E
    // 阶段后继续保留的 ARM9 续接。
    .orga Fp1ContextOffset
fp1_context:
    .dw Arm9ReturnTrampolineAddress
    .dw 0xe1a00000
    .dw 0xe599f000
    .dw REG_IPC_SYNC
    .dw 0x00000e00
    .dw Arm9ReturnSlot

    .orga Fp1ColdPrepareOffset
fp1_cold_prepare:
    mov r11, lr
    mov r0, #0
    mov r2, #0x2c
    ldr r1, =REG_DMA0SAD

fp1_clear_dma:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_dma

    mov r0, #1
    swi 0x1f0000
    ldr r1, =REG_POWERCNT
    mov r0, #0
    strh r0, [r1]

    // Map all VRAM to LCDC, clear it, then put shared WRAM under ARM7 control.
    // 将全部 VRAM 映射到 LCDC、清零，再把共享 WRAM 交给 ARM7。
    ldr r4, =VRAM_A_CR
    ldr r5, =VramLcdcDisableAll
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    // Preserve the V7 historical immediate encodings rather than armips'
    // equivalent canonical rotations.
    // 保留 V7 的历史立即数编码，而非 armips 语义相同的规范旋转编码。
    .dw 0xe3a01668
    .dw 0xe3a02aa4
    bl fp1_zero_range
    .dw 0xe3a057c0
    strh r5, [r4]
    strh r5, [r4, #2]
    str r5, [r4, #4]
    strh r5, [r4, #8]

    .dw 0xe3a037a0
    ldrb r0, [r3, #-4]
    cmp r0, #0
    beq fp1_wait_e_cold
    .dw 0xe2431f80
    .dw 0xe3a02f5c
    bl fp1_zero_range
    ldr r0, =Fp1ClearSourceAddress
    .dw 0xe2431f50
    mov r2, #0x28
    swi SwiArm7CpuFastSetImmediate

fp1_wait_e_cold:
    ldr r0, =REG_POWERCNT
    ldr r1, =Arm9BootState
    strh r1, [r0]
    .dw 0xe3a01670
    .dw 0xe3a02e80
    bl fp1_zero_range
    .dw 0xe3a01650
    .dw 0xe3a02e80
    bl fp1_zero_range
    .dw 0xe3a00ee0
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

    // Keep the literal table at the original V7 offsets.  armips de-duplicates
    // repeated symbolic loads within this pool.
    // 将字面量表固定在原始 V7 偏移；armips 会在此 pool 内去重重复的符号加载。
    .orga Fp1PoolOffset
    .pool
    .endarea

fp1_retail:
    .incbin "temp/p1.bin"

    .if !BuildStealth
        // Normal V7 New patches four retail P1 checks before the two shared
        // callback bypasses below.
        // 常规版 V7 New 会先修改四处零售 P1 检查，再应用下方两个共享回调绕过。
        .orga FlashMePrefixBytes + 0x2dc
        .thumb
        lsl r3, r4, #0

        .orga FlashMePrefixBytes + 0x89e
        .thumb
        cmp r1, #1

        .orga FlashMePrefixBytes + 0x8ba
        .thumb
        cmp r0, #1

        .orga FlashMePrefixBytes + 0x8ce
        .thumb
        lsl r0, r0, #0
    .endif

    // Both V7 New variants force the two retail callback branches to fall
    // through.  The zero Thumb halfword is the historical patch encoding.
    // 两个 V7 New 变体都会强制两处零售回调分支顺序落下；零 Thumb 半字是历史补丁编码。
    .orga FlashMePrefixBytes + 0x6de6
    .thumb
    .dh 0x0000

    .orga FlashMePrefixBytes + 0x6e3c
    .thumb
    .dh 0x0000
.close

// =============================================================================
// C flow model (English)
// =============================================================================
// FP1 consumes the phase produced by FP2.  B resumes the retained P1 body;
// C clears ARM9-visible state and installs the return trampoline.  The normal
// B path waits for E after FP2's service loop, whereas Stealth enters retained
// P1 immediately.  In both C paths the trampoline holds a NOP and an indirect
// PC load through r9, with r9 pointing to Arm9ReturnSlot.
//
// static __attribute__((noreturn)) void RunFp1V7(bool stealth)
// {
//     while ((REG_IPC_SYNC & 0x0f) < 0x0b) { }
//     if ((REG_IPC_SYNC & 0x0f) == 0x0b) {
//         if (!stealth) {
//             REG_POWERCNT = Arm9BootState;
//             while ((REG_IPC_SYNC & 0x0f) != 0x0e) { }
//         }
//         EnterRetailP1(*(volatile u32 *)Arm9ReturnSlot);
//     }
//
//     PrepareArm9MemoryAndVideo();
//     InstallReturnTrampoline(Arm9ReturnTrampolineAddress,
//                             Arm9ReturnSlot, REG_IPC_SYNC, 0x0e00);
// }
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
// FP1 消费 FP2 发布的阶段值。B 会恢复保留的 P1 主体；C 会清理 ARM9 可见状态并安装
// 返回跳板。常规版 B 路径会在 FP2 服务循环后等待 E；Stealth 则立即进入零售 P1。
// 两种 C 路径中，跳板均包含 NOP 与通过 r9 进行的间接 PC 加载，其中 r9 指向
// Arm9ReturnSlot。
//
// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// This prefix is the ARM9 consumer in the V7 New second-stage pair.  FP2 owns
// route detection and uses IPC B/C/E as the cross-CPU protocol; FP1 does not
// parse the firmware header or load components.  Its 0x400-byte size places the
// preserved V3 P1 exactly at RetailP1RamAddress.  The normal/Stealth difference
// is limited to the B-route service wait and the compact layout needed for it.
//
// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// 此前置代码是 V7 New 第二阶段程序对中的 ARM9 消费端。FP2 负责路径检测，并以 IPC
// 的 B/C/E 作为跨 CPU 协议；FP1 不解析固件头，也不加载组件。其 0x400 字节大小使
// 保留的 V3 P1 恰好落在 RetailP1RamAddress。常规版与 Stealth 的差异仅限于 B 路径的
// 服务等待及其所需的紧凑布局。
