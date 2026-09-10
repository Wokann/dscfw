// Stage 1 ARM9 half: the primary parking gate described by H.  Primary P2 runs
// on ARM7 at the same time and releases this gate by changing the literal word
// at P1 +0x08.  See the whole-program map in main.s before reading this file.
// 第一阶段的 ARM9 一半：由 H 描述的一级等待闸门。一级 P2 会同时在 ARM7 上运行，
// 并通过改写 P1 +0x08 的字面量字来放行本闸门。阅读本文件前请先看 main.s 的完整时序图。
.create "build/p1.bin", 0
    .headersize PrimaryP1RamAddress
    .arm
    // V7 Old is a pure parking gate: the literal starts as its own entry, so the
    // LDR/BX pair loops until primary P2 publishes a continuation at +0x08.
    // V7 Old 是纯等待闸门：字面量初值为自身入口，因此 LDR/BX 会循环，直至一级 P2
    // 在 +0x08 发布续接地址。
    ldr r0, =PrimaryP1RamAddress
    bx r0
    .pool
p1_primary_end:
    // Keep the primary gate inside the dynamically selected 64 KiB staging page.
    // 确保一级闸门始终位于动态选定的 64 KiB 暂存页之内。
    .if p1_primary_end > PrimaryP1StagingRegionEnd
        .error "FlashMe: primary P1 exceeds its staging page"
    .endif
.close

// =============================================================================
// C flow model (English)
// =============================================================================
// This is one comment-only C representation of the primary ARM9 parking gate.
// It is deliberately not a second build target: the compact assembly above is
// the image implementation.  `primaryP1Ram` is a derived layout value, not a
// fixed version-specific literal.
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
// 这是一级 ARM9 等待闸门的一份仅作注释的 C 表达。它刻意不是第二套构建目标：上方
// 紧凑汇编才是镜像实现。`primaryP1Ram` 是推导得到的布局值，不是固定版本字面量。
//
// typedef struct {
//     uintptr_t primaryP1Ram;
// } FlashMePrimaryArm9Layout;
//
// static __attribute__((noreturn)) void Arm9TailJump(uintptr_t target)
// {
//     __asm__ volatile ("bx %0" :: "r"(target) : "memory");
//     __builtin_unreachable();
// }
//
// static __attribute__((noreturn))
// void PrimaryP1ParkingGate(const FlashMePrimaryArm9Layout *layout)
// {
//     volatile u32 *const continuationSlot = (volatile u32 *)(
//         layout->primaryP1Ram + 0x08);
//
//     // English: The initial word is P1, so BX re-enters the LDR/BX loop.
//     // 中文：该字的初值为 P1，因此 BX 会重新进入 LDR/BX 等待循环。
//     // English: Primary P2 later overwrites this word to release ARM9.
//     // 中文：一级 P2 稍后覆写该字，从而放行 ARM9。
//     Arm9TailJump(*continuationSlot);
// }

// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// P1 is intentionally not a loader and does not choose a boot route.  H starts
// it concurrently with P2.  In V7 Old it has no inherited store at all: it is a
// zero-work parking gate from its first instruction.  The literal at P1 +0x08
// initially names P1 itself, so the LDR/BX pair continually branches back to
// the LDR without touching loader state.
//
// P2 is the sole producer for this gate.  After P2 has either selected the
// Slot-2-compatible path or loaded FP1/FP2 from FH, it replaces exactly that
// literal with the selected ARM9 continuation.  P1's next LDR observes the new
// word and BX transfers into the continuation.  Thus the two CPUs synchronize
// by one mutable shared-RAM word, not by a conventional cross-CPU call or a
// return chain.
//
// The placement is equally deliberate.  symbol.inc derives P1 from the page
// below the retail ARM9 region rather than embedding a final address; FP1 is
// separately placed immediately before the retained retail P1 entry.  The size
// assertion above guards the P1 staging page, while symbol.inc guards the FP1
// prefix against that page.  This keeps the tiny first-stage gate independent
// from the larger second-stage ARM9 body.
//
// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// P1 有意不承担加载器职责，也不负责选择引导路径。H 会同时启动 P1 与 P2；在 V7 Old 中它
// 从第一条指令起就是纯零工作等待闸门，不再保留任何继承写入操作。P1 +0x08 的字面量
// 初值指向 P1 自身，因此 LDR/BX 对会持续回到 LDR，而不会触碰加载器状态。
//
// P2 是该闸门唯一的生产者。P2 完成 Slot-2 兼容路径选择，或从 FH 加载 FP1/FP2 后，
// 会将同一个字面量替换成已选择的 ARM9 续接地址。P1 的下一次 LDR 会读到新字，BX 随即
// 转入该续接。因此两颗 CPU 是借由一个可修改的共享 RAM 字进行同步，而不是依靠常规的
// 跨 CPU 函数调用或返回链。
//
// 地址放置同样是有意设计的。symbol.inc 会从零售 ARM9 区域下方的页面推导 P1，而不是
// 嵌入最终地址；FP1 则独立地放在保留零售 P1 入口之前。上方大小断言保护 P1 暂存页，
// symbol.inc 则保护 FP1 前置区不与该页重叠。这样很小的第一阶段闸门便可与较大的第二
// 阶段 ARM9 主体保持独立。
