// Stage 1 ARM9 half: the primary parking gate described by H.  Primary P2 runs
// on ARM7 at the same time and releases this gate by changing the literal word
// at P1 +0x0C.  See the whole-program map in main.s before reading this file.
// 第一阶段的 ARM9 一半：由 H 描述的一级等待闸门。一级 P2 会同时在 ARM7 上运行，
// 并通过改写 P1 +0x0C 的字面量字来放行本闸门。阅读本文件前请先看 main.s 的完整时序图。
.create "build/p1.bin", 0
    .headersize PrimaryP1RamAddress
    .arm
    str r0, [r12, r0, lsl #3]
    // The mutable continuation word is a named slot, so armips derives the
    // PC-relative displacement instead of the source carrying one by hand.
    // 可修改的续接字使用命名槽，因此由 armips 推导 PC 相对位移，而不是在源码中手写。
    ldr r0, [p1_handoff_slot]
    bx r0
p1_handoff_slot:
    .dw PrimaryP1RamAddress + 4
    // The historical component ends with one zero word after its LDR literal.
    // 旧版组件在 LDR 字面量之后以一个零字结束。
    .dw 0x00000000
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
// void PrimaryP1ParkingGate(u32 incomingValue,
//                           volatile u32 *retailWorkArea,
//                           const FlashMePrimaryArm9Layout *layout)
// {
//     // English: A u32 index of incomingValue << 1 is r12 + (r0 << 3).
//     // 中文：对 u32 数组使用 incomingValue << 1 索引，等价于 r12 + (r0 << 3)。
//     retailWorkArea[(size_t)incomingValue << 1] = incomingValue;
//
//     volatile u32 *const continuationSlot = (volatile u32 *)(
//         layout->primaryP1Ram + 0x0c);
//
//     // English: The initial word is P1 + 4, so BX re-enters the LDR/BX loop.
//     // 中文：该字的初值为 P1 + 4，因此 BX 会重新进入 LDR/BX 等待循环。
//     // English: Primary P2 later overwrites this word to release ARM9.
//     // 中文：一级 P2 稍后覆写该字，从而放行 ARM9。
//     Arm9TailJump(*continuationSlot);
// }

// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// P1 is intentionally not a loader and does not choose a boot route.  H starts
// it concurrently with P2, and P1 first preserves the one inherited store whose
// exact retail data structure is still unknown.  It then becomes a zero-work
// parking gate: the literal at P1 +0x0C initially names P1 +4, so the LDR/BX
// pair continually branches back to itself without touching loader state.
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
// P1 有意不承担加载器职责，也不负责选择引导路径。H 会同时启动 P1 与 P2；P1 首先
// 保留一次继承而来的写入操作，其准确的零售数据结构含义尚未恢复。之后它成为一个零工作
// 等待闸门：P1 +0x0C 的字面量初值指向 P1 +4，因此 LDR/BX 对会持续跳回自身，不会触碰
// 加载器状态。
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
