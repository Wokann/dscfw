// Stage 2 ARM9 half.  Primary P2 has already loaded this FH-described image;
// FP2 now runs concurrently on ARM7 and publishes the IPC phase consumed here.
// The first 0x200 bytes are new code, followed by the retained retail P1 body
// at its original runtime address.  See main.s for the complete two-CPU map.
// 第二阶段的 ARM9 一半。一级 P2 已经加载了这个由 FH 描述的镜像；FP2 此时会在
// ARM7 上并行运行，并发布由本代码消费的 IPC 阶段值。开头 0x200 字节是新代码，
// 之后是仍处于原始运行地址的零售 P1 主体。完整双 CPU 时序请参见 main.s。
.create "build/fp1.bin", 0
    .headersize FlashMeFp1RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm
    // The context's r9 word doubles as the first literal slot.  Referencing it
    // by name retains the historical V5 layout while ARMIPS derives the offset.
    // 上下文的 r9 字同时复用为第一个字面量槽。以名称引用既保留历史 V5 布局，又由
    // ARMIPS 推导偏移。
    ldr r10, [fp1_context_ipc_sync]

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    subs r0, r0, #0x0b
    bmi fp1_wait_b
    bne fp1_cold_boot

    .if BuildStealth
    // English: Stealth takes the B route directly into retained P1.  It does
    // not publish the normal warm-path power write or wait for the D barrier.
    // 中文：Stealth 会把 B 路径直接转入保留 P1，不执行常规热路径的电源写入，
    // 也不等待 D 屏障。
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
    // V5 keeps the two VRAM values after its ordinary slots.  These labels
    // preserve that order while removing the handwritten PC displacements.
    // V5 会把两个 VRAM 值放在普通槽之后。以下标签保留该顺序，同时移除手写 PC 位移。
    ldr r4, [fp1_slot_vram_a_cr]
    ldr r5, [fp1_slot_vram_lcdc_enable_abcd]
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    // The FlashMe ARMIPS profile selects the historical immediate rotations.
    // FlashMe ARMIPS 配置会选择历史立即数旋转编码。
    mov r1, #VRAM_A
    mov r2, #VramLcdcBytes
    bl fp1_zero_range
    // Disable VRAM banks A-I, then assign all shared WRAM to ARM7.
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
    // Restored into r0-r11; r4-r7 become the installed ARM trampoline.
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

// These three words are copied by the r0-r11 hand-off to Arm9ReturnSlotNext.
// Rebase only this output range to its runtime location so the LDR target is a
// named slot rather than a handwritten PC displacement.
// 这三个字会由 r0-r11 交接复制到 Arm9ReturnSlotNext。仅重映射该输出范围，使 LDR
// 目标成为命名槽而非手写 PC 位移。
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

// Preserve the variant-specific historical slot order.
// 保留不同变体各自的历史槽顺序。
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
    // RetailP1RamAddress = FlashMeFp1RamAddress + FlashMePrefixBytes.
    // 零售 P1 的运行地址等于 FlashMeFp1RamAddress + FlashMePrefixBytes。
    // This .incbin begins at output +0x200, so fp1_retail is exactly the retail
    // P1 entry address.  The retained body can therefore keep its original
    // absolute addresses; the prefix did not relocate it.
    // 此 .incbin 从输出 +0x200 开始，因此 fp1_retail 恰好就是零售 P1 的入口地址。
    // 保留的主体可以继续使用原有绝对地址；前置代码并没有搬移它。
    .incbin "temp/p1.bin"

    .if !BuildStealth
    // English: The normal V5 body changes the early register transfer and two
    // setup limits, then removes a conditional callback branch.  These are
    // Thumb encodings chosen to match the historical component exactly.
    // 中文：常规 V5 主体会修改早期寄存器传递与两个设置上限，并移除一个条件回调
    // 跳转。这些 Thumb 编码按历史组件逐字节选择。
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

    // English: FP1 has a 0x200-byte prefix, so this output offset corresponds
    // to Nintendo original V3 P1 +0x6DE6. The retained routine decompresses
    // two regions, chains them through BIOS SWI 0x0E (CRC16), and compares the
    // result with the expected 16-bit CRC. Its original `bne` selects the
    // mismatch notification (0x408); replacing it with the zero Thumb NOP
    // makes both outcomes follow the valid-CRC notification (0x400). This
    // bypasses the first retained-body CRC16 integrity gate so the altered
    // component chain can continue booting.
    // 中文：FP1 含有 0x200 字节前置代码，因此该输出偏移对应任天堂原始 V3 P1
    // +0x6DE6。保留例程先解压两段数据，再依次经 BIOS SWI 0x0E（CRC16）计算，
    // 并与预期的 16 位 CRC 比较。原来的 `bne` 会选择失配通知（0x408）；替换为零值
    // Thumb NOP 后，无论结果如何都会进入有效 CRC 通知（0x400）。这会绕过第一个保留
    // 主体 CRC16 完整性门，使已改写的组件链能够继续启动。
    .org RetailP1RamAddress + 0x6de6
    .thumb
    .dh 0x0000

    // English: This output offset maps to Nintendo original V3 P1 +0x6E3C.
    // Its retained routine decompresses a region, calculates CRC16 through BIOS
    // SWI 0x0E, and normally uses `bne` to skip a boot-state notification when
    // that CRC does not match its expected 16-bit value. Replacing the branch
    // with the zero Thumb NOP makes the notification run for both outcomes.
    // It removes a second CRC16-dependent integrity gate; the parent dispatcher
    // still determines the specific later boot-state action.
    // 中文：该输出偏移对应任天堂原始 V3 P1 +0x6E3C。其保留例程会先解压一段数据，
    // 再经 BIOS SWI 0x0E 计算 CRC16；原来仅当该 CRC 与预期 16 位值相等时才会避开
    // `bne` 并执行启动状态通知。替换为零值 Thumb NOP 后，CRC 相等或不等都会执行该
    // 通知。这移除了第二个依赖 CRC16 的完整性门；其后的具体启动状态仍由上层分派器决定。
    .org RetailP1RamAddress + 0x6e3c
    .thumb
    .dh 0x0000
.close

// =============================================================================
// C flow model (English)
// =============================================================================
// This is one comment-only C representation of the secondary ARM9 prefix.  It
// models the B/C/D IPC protocol, but does not replace the exact ARM register
// hand-off implemented above.  FP1 and the retained retail P1 entry are always
// related by the derived prefix length, rather than a fixed RAM literal.
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
// 这是二级 ARM9 前置代码的一份仅作注释的 C 表达。它描述 B/C/D IPC 协议，但不取代
// 上方精确的 ARM 寄存器交接。FP1 与保留零售 P1 入口始终通过推导出的前置区长度关联，
// 而不是固定 RAM 字面量。
//
// typedef struct {
//     uintptr_t fp1Ram;
//     size_t prefixBytes;
//     uintptr_t arm9ReturnSlot;
//     uintptr_t arm9ReturnSlotNext;
//     u16 arm9BootState;
// } FlashMeFp1Layout;
//
// static u16 IpcPhase(void) { return REG_IPC_SYNC & 0x000f; }
//
// static void ZeroRange(volatile u16 *firstHalfword, size_t byteCount)
// {
//     while (byteCount != 0) {
//         firstHalfword[0] = firstHalfword[1] = 0;
//         firstHalfword[2] = firstHalfword[3] = 0;
//         firstHalfword += 4;
//         byteCount -= 8;
//     }
// }
//
// static __attribute__((noreturn)) void EnterRetailP1(uintptr_t entry,
//                                                     uintptr_t returnLink);
// static __attribute__((noreturn)) void RestoreContextAndJump(
//     const Fp1RegisterContext *context);
//
// static __attribute__((noreturn)) void SecondaryFp1(
//     const FlashMeFp1Layout *layout)
// {
//     u16 phase;
//     do phase = IpcPhase(); while (phase < 0x000b);
//
//     if (phase == 0x000b) {
//         // English: Stealth enters retained P1 immediately; normal V5 restores
//         // power and waits for D before entering the same body.
//         // 中文：Stealth 会立刻进入保留 P1；常规 V5 则恢复电源并等待 D，随后进入
//         // 同一个主体。
//         if (!BuildStealth) {
//             REG_POWERCNT = layout->arm9BootState;
//             do phase = IpcPhase(); while (phase != 0x000d);
//         }
//         EnterRetailP1(layout->fp1Ram + layout->prefixBytes,
//                       *(volatile u32 *)layout->arm9ReturnSlot);
//     }
//
//     // English: C selects the cold route and prepares VRAM/WRAM for ARM7.
//     // 中文：C 选择冷启动路径，并为 ARM7 准备 VRAM/WRAM。
//     volatile u8 *const vramControl = &VRAM_A_CR;
//     for (int offset = 0x2c; offset >= 0; offset -= 4)
//         *(volatile u32 *)(vramControl + offset) = 0;
//     REG_POWERCNT = 0;
//     for (unsigned bank = 0; bank < 9; ++bank)
//         vramControl[bank] = VRAM_ENABLE | VRAM_A_LCD;
//     ZeroRange((volatile u16 *)VRAM_A, 0x0a4000);
//     for (unsigned bank = 0; bank < 9; ++bank)
//         vramControl[bank] = 0;
//     WRAM_CR = 3;
//
//     do phase = IpcPhase(); while (phase != 0x000d);
//     REG_POWERCNT = layout->arm9BootState;
//     ZeroRange((volatile u16 *)OAM, 0x0800);
//     ZeroRange((volatile u16 *)BG_PALETTE, 0x0800);
//
//     // English: The final context writes the ARM9 trampoline and tail-jumps.
//     // 中文：最后的上下文会写入 ARM9 跳板并进行尾跳转。
//     const Fp1RegisterContext context = MakeFp1Context(layout);
//     RestoreContextAndJump(&context);
// }

// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// FP1 begins only after primary P2 has loaded the FH-described pair.  It is the
// ARM9 consumer of a simple phase protocol produced by FP2 on ARM7: low nibble
// B selects the retained-P1 route, C selects the FlashMe cold path, and D is
// the rendezvous used by the normal V5 path.  FP1 does not repeat FP2's route
// decision; it reacts to the published phase, which keeps ARM7 policy and ARM9
// video preparation separated.
//
// On B, normal V5 restores the expected power value and waits for D; Stealth
// omits both operations and tail-jumps into retained P1 immediately.  On C,
// both variants clear the DMA/control register range beginning at REG_DMA0SAD,
// temporarily map VRAM through LCDC to clear it, disable the banks again, and
// assign shared WRAM to ARM7.  They
// then wait for D, restore power, clear OAM/palette memory, and install the
// four-word ARM9 return trampoline through the exact r0-r11 context hand-off.
//
// FP1's prefix is placed immediately before the retail P1 entry, so the
// retained body runs at its original address and keeps its absolute-address
// assumptions.  Normal V5 applies six Thumb edits after control enters that
// retained body; Stealth applies its two forced-callback edits only.  They are
// deliberately separate from the phase and memory-preparation work implemented
// by the prefix.
//
// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// FP1 只有在一级 P2 加载由 FH 描述的组件对之后才会开始。它是 ARM9 上的阶段消费者，
// 阶段由 ARM7 上的 FP2 发布：低半字节 B 选择保留 P1 路径，C 选择 FlashMe 冷启动路径，
// D 是常规 V5 路径使用的会合点。FP1 不会重复 FP2 的路径决策；它只响应已发布的阶段，
// 从而将 ARM7 策略与 ARM9 显示准备工作分开。
//
// 在 B 路径上，常规 V5 会恢复预期电源值并等待 FP2 到达 D；Stealth 则省略两步并立刻
// 尾跳转至保留 P1。在 C 路径上，两种变体都会清除从 REG_DMA0SAD 开始的 DMA/控制
// 寄存器范围，临时以 LCDC 映射 VRAM 以清零，再次关闭各 bank，并将共享 WRAM 分配给 ARM7。随后它们等待 D，恢复
// 电源、清除 OAM/调色板内存，并通过精确的 r0-r11 上下文交接安装四字 ARM9 返回跳板。
//
// FP1 前置代码被放在零售 P1 入口之前，因此保留主体仍在原始地址运行，能够保留绝对
// 地址假设。常规 V5 会在控制权进入该保留主体后应用六处 Thumb 修改；Stealth 只应用
// 其中两处强制回调修改。它们刻意与前置代码负责的阶段同步和内存准备工作分离。
