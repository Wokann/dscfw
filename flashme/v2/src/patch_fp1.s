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
    // The context already carries REG_IPC_SYNC for r9.  Referencing its named
    // slot lets armips derive the historical PC-relative displacement.
    // 上下文已为 r9 保存 REG_IPC_SYNC。引用其命名槽可让 armips 推导历史的
    // PC 相对位移。
    ldr r10, [fp1_context_ipc_sync]

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    subs r0, r0, #0x0b
    bmi fp1_wait_b
    bne fp1_cold_boot
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

fp1_cold_boot:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, [fp1_slot_dma0_src]

fp1_clear_dma_control:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_dma_control
    mov r0, #1
    swi SwiArm9CustomPostImmediate
    ldr r1, [fp1_slot_powercnt]
    mov r0, #0
    strh r0, [r1]
    ldr r4, [fp1_slot_vram_a_cr]
    ldr r5, [fp1_slot_vram_lcdc_enable_abcd]
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
    // The FlashMe ARMIPS profile selects the historical rotated-immediate
    // encoding, so these are ordinary instructions rather than raw words.
    // FlashMe ARMIPS 配置会选择历史的旋转立即数编码，因此此处使用普通指令而非原始字。
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

    .org FlashMeFp1RamAddress + 0x108
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
// Rebase only this output range to its runtime location, so actual mnemonics
// can derive the trampoline's backward LDR target from a named slot.
// 这三个字会由 r0-r11 交接复制到 Arm9ReturnSlotNext。仅将此输出范围重映射到其
// 运行时位置，使真实助记符可从命名槽推导跳板的向后 LDR 目标。
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

// Keep these explicitly ordered slots at the former literal-pool location.
// 命名槽保持在原字面量池的位置和顺序。
fp1_slot_powercnt:
    .dw REG_POWERCNT
fp1_slot_arm9_boot_state:
    .dw Arm9BootState
fp1_slot_arm9_return:
    .dw Arm9ReturnSlot
fp1_slot_dma0_src:
    .dw DMA0_SRC
fp1_slot_vram_a_cr:
    .dw VRAM_A_CR
fp1_slot_vram_lcdc_enable_abcd:
    .dw VramLcdcEnableAbcd
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

    // English: This inferred V2 pair is deliberately smaller than V3's four
    // retained-P1 edits.  +0x2DC is a signed halfword in the state-zero jump
    // table, not executed Thumb code: 0x0017 selects the existing +0x0AAC
    // handler and 0x0023 selects the existing +0x0884 handler.  The latter is
    // the alternate startup-state path used by V3.  V2 therefore changes only
    // this table entry and the branch below which otherwise skips its state
    // handling.  The V1 0x0F timing gates at +0x89E and +0x8BA are intentionally
    // retained, so V3's shortened display/fade timing is not imported.
    //
    // 中文：这对推断出的 V2 修改刻意小于 V3 的四处保留 P1 改动。+0x2DC 是状态 0
    // 跳转表中的有符号半字，而不是会执行的 Thumb 代码：0x0017 会选择已有的 +0x0AAC
    // 处理程序，0x0023 会选择已有的 +0x0884 处理程序；后者正是 V3 使用的替代启动状态
    // 路径。因此 V2 只改这一项表值，以及下方原本会跳过其状态处理的分支。+0x89E 与
    // +0x8BA 的 V1 版 0x0F 时序门会刻意保留，故不会带入 V3 缩短后的显示/渐变时序。
    .org RetailP1RamAddress + 0x2dc
    .dh 0x0023

    // English: At retail P1 +0x8CE, replace the original unconditional branch
    // with Thumb's zero NOP so the selected alternate handler can fall through
    // into its existing state-handling block.
    // 中文：在零售 P1 +0x8CE，把原有无条件跳转替换为 Thumb 的零值 NOP，使选中的
    // 替代处理程序能够顺序进入其已有的状态处理块。
    .org RetailP1RamAddress + 0x8ce
    .thumb
    lsl r0, r0, #0

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
    lsl r0, r0, #0

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
    lsl r0, r0, #0
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
//         // English: B selects the warm/service route; wait for the D rendezvous.
//         // 中文：B 选择热启动/服务路径；随后等待 D 会合点。
//         REG_POWERCNT = layout->arm9BootState;
//         do phase = IpcPhase(); while (phase != 0x000d);
//         EnterRetailP1(layout->fp1Ram + layout->prefixBytes,
//                       *(volatile u32 *)layout->arm9ReturnSlot);
//     }
//
//     // English: C selects the cold route and prepares VRAM/WRAM for ARM7.
//     // 中文：C 选择冷启动路径，并为 ARM7 准备 VRAM/WRAM。
//     volatile u8 *const vramControl = &VRAM_A_CR;
//     for (int offset = 0x2c; offset >= 0; offset -= 4)
//         *(volatile u32 *)(vramControl + offset) = 0;
//     Arm9CustomPostSwi(1);
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
//
// static void ApplyInferredV2RetailP1Patches(volatile u16 *retailP1)
// {
//     // English: +0x02DC is state-table data, not an instruction.  The V1
//     // counter gates at +0x089E/+0x08BA are intentionally left untouched.
//     // 中文：+0x02DC 是状态表数据，而非指令。+0x089E/+0x08BA 的 V1 计数门
//     // 会刻意保持不变。
//     retailP1[0x02dc / sizeof(*retailP1)] = 0x0023;
//     retailP1[0x08ce / sizeof(*retailP1)] = ThumbNopZero;
//
//     // English: These two callback fall-through edits are inherited from V1.
//     // 中文：以下两处回调落入修改继承自 V1。
//     retailP1[0x6de6 / sizeof(*retailP1)] = ThumbNopZero;
//     retailP1[0x6e3c / sizeof(*retailP1)] = ThumbNopZero;
// }

// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// FP1 begins only after primary P2 has loaded the FH-described pair.  It is the
// ARM9 consumer of a simple phase protocol produced by FP2 on ARM7: low nibble
// B selects service/warm startup, C selects the FlashMe cold path, and D is the
// rendezvous observed by both paths.  FP1 does not repeat FP2's route decision;
// it reacts to the published phase, which keeps the ARM7 policy and ARM9 video
// preparation separated.
//
// On B, FP1 restores the expected power value, waits until FP2 reaches D, loads
// the ARM9 return link prepared by the ARM7 path, and branches directly into the
// retained retail P1 body.  On C, it clears the VRAM control range, performs the
// inherited ARM9 SWI, temporarily maps VRAM through LCDC to clear it, disables
// the banks again, and assigns shared WRAM to ARM7.  It then waits for D before
// restoring power, clearing OAM/palette memory, and installing the four-word
// ARM9 return trampoline through the exact r0-r11 context hand-off.
//
// FP1's prefix is placed immediately before the retail P1 entry, so the
// retained body runs at its original address and keeps its absolute-address
// assumptions.  The two inferred V2 edits and two inherited V1 callback edits
// below apply only after control enters that retained body.  The V2 pair selects
// an existing alternate startup state and permits its state handling; it remains
// deliberately separate from the phase and memory-preparation work implemented
// by the prefix.
//
// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// FP1 只有在一级 P2 加载由 FH 描述的组件对之后才会开始。它是 ARM9 上的阶段消费者，
// 阶段由 ARM7 上的 FP2 发布：低半字节 B 选择服务/热启动，C 选择 FlashMe 冷启动路径，
// D 则是两条路径都会观察到的会合点。FP1 不会重复 FP2 的路径决策；它只响应已发布的
// 阶段，从而将 ARM7 策略与 ARM9 显示准备工作分开。
//
// 在 B 路径上，FP1 恢复预期电源值，等待 FP2 到达 D，读取 ARM7 路径准备好的 ARM9
// 返回链接，并直接跳入保留的零售 P1 主体。在 C 路径上，它清除 VRAM 控制范围，执行
// 继承的 ARM9 SWI，临时以 LCDC 映射 VRAM 以清零，再次关闭各 bank，并将共享 WRAM
// 分配给 ARM7。随后它等待 D，恢复电源、清除 OAM/调色板内存，并通过精确的 r0-r11
// 上下文交接安装四字 ARM9 返回跳板。
//
// FP1 前置代码被放在零售 P1 入口之前，因此保留主体仍在原始地址运行，能够保留绝对
// 地址假设。下方两处推断的 V2 修改及两处继承自 V1 的回调修改只会在控制权进入该保留
// 主体后才会生效。V2 的一对改动会选择已有的替代启动状态并允许其状态处理，其与前置代码
// 负责的阶段同步和内存准备工作刻意分离。
