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
    ldr r10, =REG_IPC_SYNC

fp1_wait_b:
    ldrh r0, [r10]
    and r0, r0, #0x0f
    subs r0, r0, #0x0b
    bmi fp1_wait_b
    bne fp1_cold_boot
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

fp1_cold_boot:
    mov r0, #0
    mov r2, #0x2c
    ldr r1, =VRAM_A_CR

fp1_clear_video_control:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp1_clear_video_control
    mov r0, #1
    swi SwiArm9CustomPostImmediate
    ldr r1, =REG_POWERCNT
    mov r0, #0
    strh r0, [r1]
    ldr r4, =VRAM_A_CR
    ldr r5, =VramLcdcEnableAbcd
    str r5, [r4]
    strh r5, [r4, #4]
    strb r5, [r4, #6]
    strh r5, [r4, #8]
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
    ldr r0, =REG_POWERCNT
    ldr r1, =Arm9BootState
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

    .orga 0x108
fp1_context:
    // Restored into r0-r11; r4-r7 become the installed ARM trampoline.
    .dw Fp1ContextR0, Fp1ContextR1, Fp1ContextR2, Fp1ContextR3
    .dw Arm9ReturnSlotNext
    .dw Fp1TrampolineStoreHalfword, Fp1TrampolineLoadTarget, Fp1TrampolineBranchTarget
    .dw Fp1ContextR8, REG_IPC_SYNC, Fp1ContextR10, Arm9ReturnSlot
    .pool
    .endarea

fp1_retail:
    // This .incbin begins at output +0x200, so fp1_retail is exactly the retail
    // P1 entry address.  The retained body can therefore keep its original
    // absolute addresses; the prefix did not relocate it.
    // 此 .incbin 从输出 +0x200 开始，因此 fp1_retail 恰好就是零售 P1 的入口地址。
    // 保留的主体可以继续使用原有绝对地址；前置代码并没有搬移它。
    .incbin "temp/p1.bin"

    // English: FP1 has a 0x200-byte prefix, so this output offset corresponds
    // to retail P1 +0x6DE6.  Retail code compares r4 with a 16-bit reference
    // and uses `bne` to select an alternate callback at +0x6DF6.  Writing the
    // Thumb halfword 0x0000 removes that conditional branch, always selecting
    // the fall-through callback path instead.  The checked value's high-level
    // identity is intentionally left unnamed until the surrounding routine is
    // fully recovered.
    // 中文：FP1 含有 0x200 字节前置代码，因此该输出偏移对应零售 P1 +0x6DE6。
    // 零售代码会将 r4 与一个 16 位参考值比较，并用 `bne` 选择 +0x6DF6 的另一回调。
    // 写入 Thumb 半字 0x0000 会移除该条件跳转，始终改走顺序落下的回调路径。被检查值
    // 的高层含义会在完整恢复周边例程前刻意不作命名。
    .orga 0x6fe6
    .thumb
    .dh 0x0000

    // English: This output offset maps to retail P1 +0x6E3C.  Retail code uses
    // `bne` to skip a callback when r4 differs from a second 16-bit reference.
    // Replacing the branch with 0x0000 makes the callback run for both equality
    // and inequality.  It therefore forces the post-comparison action without
    // claiming a semantic name for the still-unrecovered reference value.
    // 中文：该输出偏移对应零售 P1 +0x6E3C。零售代码在 r4 与第二个 16 位参考值不等时
    // 使用 `bne` 跳过一个回调。将该跳转替换为 0x0000 后，无论相等与否都会执行回调。
    // 因而它强制执行比较后的动作，同时不会在尚未完全恢复前臆测该参考值的语义名称。
    .orga 0x703c
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
// assumptions.  The two Thumb halfword edits below apply only after control
// enters that retained body; they are deliberately separate from the phase and
// memory-preparation work implemented by the prefix.
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
// 地址假设。下方两处 Thumb 半字修改只会在控制权进入该保留主体后才生效；它们刻意与
// 前置代码负责的阶段同步和内存准备工作分离。
