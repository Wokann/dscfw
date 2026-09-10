// Stage 2 ARM9 half for FlashMe V6 Phat.  Primary P2 has already loaded the
// FH-described FP pair.  The first 0x200 bytes below are FlashMe code; the
// retained official V3 P1 body begins immediately afterwards at its original
// RAM entry.  main.s describes the two-CPU sequence as one program.
// FlashMe V6 Phat 的第二阶段 ARM9 部分。一级 P2 已加载 FH 所描述的 FP 组件对。
// 下方前 0x200 字节是 FlashMe 代码；随后立即接入保留的官方 V3 P1 主体，并使其
// 从原有 RAM 入口开始执行。main.s 将双 CPU 时序作为一套程序说明。
.create "build/fp1.bin", 0
    .headersize FlashMeFp1RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm
    // The IPC register is deliberately loaded from the context table instead
    // of an automatic literal.  This keeps the original V6 table layout while
    // still giving the table entry a platform-defined name.
    // IPC 寄存器有意从上下文表载入，而不是使用自动字面量。这样既保持原始 V6 表的
    // 布局，也为表项赋予平台定义的名称。
    ldr r10, [pc, #Fp1ContextOffset + 0x04]

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    subs r0, r0, #0x0b
    bmi fp1_wait_b
    bne fp1_cold_boot

    .if BuildStealth
    // Stealth does not wait for the normal B-to-D service phase.  It restores
    // the saved ARM9 link and enters the retained P1 body immediately.
    // Stealth 不等待常规版从 B 到 D 的服务阶段；它恢复保存的 ARM9 链接后立刻进入
    // 保留的 P1 主体。
    ldr lr, =Arm9ReturnSlot
    ldr lr, [lr]
    b fp1_retail
    .else
    // The normal B route restores power and waits for FP2 to publish D before
    // it resumes the retail ARM9 body.
    // 常规 B 路径会恢复电源，并等待 FP2 发布 D，再继续零售 ARM9 主体。
    ldr r0, =REG_POWERCNT
    ldr r1, =Arm9BootState
    strh r1, [r0]

fp1_wait_d_warm:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    cmp r0, #0x0d
    bne fp1_wait_d_warm
    ldr lr, =Arm9ReturnSlot
    ldr lr, [lr]
    b fp1_retail
    .endif

fp1_cold_boot:
    // Clear the inherited DMA/control-register range before touching the
    // display and shared-memory configuration.
    // 在接触显示及共享内存配置前，先清除继承的 DMA/控制寄存器范围。
    mov r0, #0
    mov r2, #0x2c
    ldr r1, =REG_DMA0SAD

fp1_clear_dma_range:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_dma_range

    // V6 invokes the inherited ARM9-side BIOS service before disabling power.
    // V6 会在关闭电源前调用继承的 ARM9 BIOS 服务。
    mov r0, #1
    swi 0x1f0000
    ldr r1, =REG_POWERCNT
    mov r0, #0
    strh r0, [r1]

    // Preserve the historical V6 literal placement for the VRAM control base
    // and the all-disabled VRAMCNT value.
    // 保留历史 V6 中 VRAM 控制基址与全关闭 VRAMCNT 值的字面量位置。
    .if BuildStealth
    ldr r4, [pc, #0xe8]
    ldr r5, [pc, #0xe8]
    .else
    ldr r4, [pc, #0xec]
    ldr r5, [pc, #0xec]
    .endif
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    // These exact words preserve the original ARM immediate encodings for
    // VRAM_A and the contiguous LCDC-clear size.
    // 下列精确字保留 VRAM_A 和连续 LCDC 清除大小的原始 ARM 立即数编码。
    .dw 0xe3a01668
    .dw 0xe3a02aa4
    bl fp1_zero_range
    // Disable all VRAM banks and assign all shared WRAM to ARM7.
    // 关闭全部 VRAM bank，并将全部共享 WRAM 分配给 ARM7。
    .dw 0xe3a057c0
    strh r5, [r4]
    strh r5, [r4, #2]
    str r5, [r4, #4]
    strh r5, [r4, #8]

    // If the inherited ARM9 staging flag is non-zero, V6 clears its adjacent
    // header area and invokes CpuFastSet on the nearby 0x28-word region.
    // 若继承的 ARM9 暂存标志非零，V6 会清除其相邻头部区域，并对附近的 0x28-word
    // 区域调用 CpuFastSet。
    // Exact V6 encodings for 0x02800000, 0x200, 0x170, and 0x140.  The
    // assembler's canonical rotations are semantically identical but differ
    // from the historical component bytes.
    // 下列是 0x02800000、0x200、0x170 与 0x140 的精确 V6 编码。汇编器的规范
    // 旋转编码在语义上相同，但会与历史组件字节不同。
    .dw 0xe3a037a0
    ldrb r0, [r3, #-4]
    cmp r0, #0
    beq fp1_wait_d_cold
    .dw 0xe2431f80
    .dw 0xe3a02f5c
    bl fp1_zero_range
    .if BuildStealth
    ldr r0, [pc, #0x9c]
    .else
    ldr r0, [pc, #0xa0]
    .endif
    .dw 0xe2431f50
    mov r2, #0x28
    swi SwiArm7CpuFastSetImmediate

fp1_wait_d_cold:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    cmp r0, #0x0d
    bne fp1_wait_d_cold
    ldr r0, =REG_POWERCNT
    .if BuildStealth
    // This direct load keeps Arm9BootState after the V6 Stealth explicit
    // literals rather than moving it into the automatic pool.
    // 此直接载入使 Arm9BootState 位于 V6 Stealth 的显式字面量之后，而不是移入
    // 自动 pool。
    ldr r1, [pc, #0x7c]
    .else
    ldr r1, =Arm9BootState
    .endif
    strh r1, [r0]
    .dw 0xe3a01670
    .dw 0xe3a02e80
    bl fp1_zero_range
    .dw 0xe3a01650
    .dw 0xe3a02e80
    bl fp1_zero_range

    // V6 restores a six-word context.  It installs a two-instruction ARM9
    // trampoline at 0x027fff70, records that trampoline in the saved return
    // slot, and branches to it.  The trampoline publishes D then reloads the
    // original ARM9 continuation.
    // V6 恢复一个六字上下文：在 0x027fff70 安装两条指令的 ARM9 跳板，将该跳板
    // 写入保存的返回槽，并跳转至它。该跳板发布 D 后重新载入原始 ARM9 续接地址。
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

    .orga Fp1ContextOffset
fp1_context:
    // Loaded into r4-r9 by the final hand-off above.
    // 由上方最终交接载入 r4-r9。
    .dw Arm9ReturnTrampolineAddress
    .dw Fp1TrampolinePublishD
    .dw Fp1TrampolineReloadReturn
    .dw REG_IPC_SYNC
    .dw Fp1IpcPhaseD
    .dw Arm9ReturnSlot
    .pool
    .dw VRAM_A_CR, VramLcdcEnableAbcd, Fp1ClearSourceAddress
    .if BuildStealth
    .dw Arm9BootState
    .endif
    .endarea

fp1_retail:
    // The source P1 begins at output +0x200, which is exactly its source-H
    // runtime entry.  It can therefore retain all absolute address assumptions.
    // 源 P1 从输出 +0x200 开始，恰好位于源 H 所描述的运行入口，因此可保留全部
    // 绝对地址假设。
    .incbin "temp/p1.bin"

    .if !BuildStealth
    // Normal V6 applies four Thumb edits in the retained V3 P1 body before
    // the two callback-force edits shared with Stealth below.
    // 常规 V6 会先在保留的 V3 P1 主体中应用四处 Thumb 修改，随后再应用下方与
    // Stealth 共用的两处强制回调修改。
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

    // Both V6 variants replace two conditional callback branches with the
    // Thumb zero halfword, forcing their fall-through paths.
    // 两个 V6 变体都会以 Thumb 零半字替换两处条件回调分支，从而强制走顺序落下路径。
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
// This comment-only C model describes the V6 secondary ARM9 prefix.  The
// assembly above is the byte-producing implementation; the model is intended
// to make the ARM7/ARM9 relationship legible, not to replace its register ABI.
//
// typedef struct {
//     volatile u16 *ipcSync;
//     volatile u16 *powerControl;
//     uintptr_t originalArm9ReturnSlot;
// } FlashMeFp1V6State;
//
// static u16 IpcPhase(const FlashMeFp1V6State *state)
// {
//     return *state->ipcSync & 0x000f;
// }
//
// static void ZeroRange(volatile u16 *firstHalfword, size_t byteCount)
// {
//     while (byteCount != 0) {
//         firstHalfword[0] = 0;
//         firstHalfword[1] = 0;
//         firstHalfword[2] = 0;
//         firstHalfword[3] = 0;
//         firstHalfword += 4;
//         byteCount -= 8;
//     }
// }
//
// static __attribute__((noreturn)) void RunFp1V6(
//     const FlashMeFp1V6State *state, bool stealth)
// {
//     u16 phase;
//     do phase = IpcPhase(state); while (phase < 0x000b);
//
//     if (phase == 0x000b) {
//         if (!stealth) {
//             *state->powerControl = Arm9BootState;
//             do phase = IpcPhase(state); while (phase != 0x000d);
//         }
//         EnterRetailP1(*(volatile u32 *)state->originalArm9ReturnSlot);
//     }
//
//     ClearDmaAndControlRegisters();
//     Arm9BiosService(1);
//     *state->powerControl = 0;
//     ClearLcdcMappedVram();
//     ConfigureWramForArm7();
//     if (Read8(FirmwarePart1RamaddrBase - 4) != 0) {
//         ZeroRange((volatile u16 *)(FirmwarePart1RamaddrBase - 0x200), 0x170);
//         Arm7CpuFastSet(Fp1ClearSourceAddress,
//                        FirmwarePart1RamaddrBase - 0x140, 0x28);
//     }
//
//     do phase = IpcPhase(state); while (phase != 0x000d);
//     *state->powerControl = Arm9BootState;
//     ZeroRange((volatile u16 *)OAM, MM_OBJRAM_SZ);
//     ZeroRange((volatile u16 *)BG_PALETTE, MM_PALRAM_SZ);
//     InstallDPublishingReturnTrampoline();
// }
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
// 这份仅作注释的 C 模型描述 V6 的二级 ARM9 前置代码。上方汇编才是产生字节的实现；
// 本模型用于让 ARM7/ARM9 的关系更易读，而不会取代其寄存器 ABI。
//
// 它先消费 FP2 发布的低四位 IPC 阶段：B 是保留 P1 的服务路径，C 是 FlashMe 冷启动
// 路径，D 是两颗 CPU 的会合点。常规版在 B 路径上等待 D；Stealth 则立刻进入保留 P1。
// 冷启动路径清除控制状态、调用 V6 仍保留的 BIOS 服务、重置显示/WRAM，并在标志存在时
// 清除 ARM9 暂存区。最后它安装一段发布 D 且回到保存续接地址的 ARM9 跳板。
//
// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// FP1 is not an independent ARM9 loader.  Primary P2 has already selected FH
// and loaded FP1/FP2 before this prefix begins.  FP2 owns route selection and
// publishes B or C through IPC; FP1 merely consumes that decision.  B returns
// to the retained retail P1 path, while C makes FP1 prepare ARM9-visible video
// and memory state before both processors rendezvous at D.
//
// The V6 return trampoline is the key final cooperation point.  FP1 writes a
// two-word program at 0x027fff70: it stores phase D to IPC_SYNC, then loads PC
// through the original ARM9 return slot.  Writing the trampoline address into
// that slot lets the inherited continuation observe the completed rendezvous
// without moving the retail P1 body.  The body remains exactly after the
// 0x200-byte prefix and its small Thumb modifications therefore operate at
// stable offsets from the original V3 code.
//
// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// FP1 不是独立的 ARM9 加载器。此项前置代码开始前，一级 P2 已选择 FH 并加载了
// FP1/FP2。FP2 负责路径选择，并经 IPC 发布 B 或 C；FP1 仅消费这个决定。B 会回到
// 保留的零售 P1 路径；C 则由 FP1 在两颗 CPU 于 D 会合前准备 ARM9 可见的视频与内存状态。
//
// V6 返回跳板是最后一个关键协作点。FP1 会在 0x027fff70 写入两字程序：先把阶段 D
// 存至 IPC_SYNC，再通过原 ARM9 返回槽加载 PC。将跳板地址写回该槽可让继承续接看到
// 已完成的会合，同时无需搬移零售 P1 主体。该主体仍紧邻 0x200 字节前置代码之后，因此
// 它的小范围 Thumb 修改仍相对于原 V3 代码位于稳定偏移。
