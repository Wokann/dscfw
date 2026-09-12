// FlashMe patch entry point.
//
// =============================================================================
// Whole-program boot map (English)
// =============================================================================
//
// This is a dual-CPU NDS boot program, not one linear sequence of C calls.
// The retail boot environment starts the ARM9 and ARM7 components named by a
// firmware header independently.  FlashMe deliberately turns that into two
// consecutive ARM9/ARM7 pairs:
//
//     H, the primary header
//       |- ARM9: P1, a waiting gate at PrimaryP1RamAddress
//       `- ARM7: P2, the primary coordinator at PrimaryP2RamAddress
//                         |
//                         | reads and interprets FH
//                         v
//     FH, the secondary header at image +0x3FC80 in this layout
//       |- ARM9: FP1 prefix + retained retail P1
//       `- ARM7: FP2 prefix + retained retail P2
//
// Stage 1 begins when the normal firmware loader interprets H.  H names only
// the small replacement P1 and P2 components; it does not name the retail P1
// and P2 bodies directly.  The ARM9 P1 stub performs its inherited register
// store, then repeatedly reloads its mutable literal word at P1 +0x0C.  That
// word initially points back to P1 +4, so ARM9 is intentionally parked in its
// LDR/BX loop while ARM7 P2 runs.  P1 is therefore not a normal subroutine that
// P2 calls later: both CPUs are already executing in parallel.
//
// Primary P2 is the coordinator of that first pair.  It preserves the retail
// boot ABI's r12 value as a header work pointer, chooses an alternate
// Slot-2/AGB-compatible branch from the key and title checks when necessary,
// and otherwise uses the ARM7 BIOS firmware-reader and LZ77 path to load the
// two FH-described components.  It decodes the descriptor units with
// shift_amounts, so the RAM addresses in FH select FP1 and FP2.  When that
// work has produced the ARM9 continuation, P2 writes it into P1 +0x0C.  The
// next iteration of P1's waiting loop then leaves the gate and reaches the
// loaded ARM9 secondary path.  The alternate branch uses the same release
// slot, but first constructs a small ARM9 trampoline for its inherited return
// path.  See patch_p1.s and patch_p2.s as the two halves of this handshake.
//
// Stage 2 is the FP1/FP2 pair described by FH.  Each component has a new
// FlashMePrefixBytes prefix followed by an included retail body.  The assembler
// decodes each retail runtime entry from source H and derives FP1/FP2 as
// `RetailP?RamAddress - FlashMePrefixBytes`; it does not bake fixed entries into
// the patch.  The prefix therefore adds code before the original entry without
// relocating the original body or invalidating its absolute-address assumptions.
// The patch derives its primary P1 gate from the 64 KiB page below that retail ARM9
// region, and derives primary P2 as the P2 format base minus its 2 KiB staging
// window.  Those are explicit placement rules rather than source-H fields.
//
// FP2 is the ARM7 member of the second pair and publishes the IPC phase which
// FP1 consumes on ARM9.  From ARM9's visible low nibble, 0xB selects retained
// P1/P2, 0xC selects the FlashMe-specific cold route, and 0xD is the normal-V4
// rendezvous.  With BuildStealth=0, FP2 performs its service timing after B,
// publishes D, and FP1 waits for D before entering retained P1.  With
// BuildStealth=1, both prefixes take their B routes directly into their retained
// bodies.  On C, both variants perform the cold ARM7/ARM9 preparation, meet at
// D, install the ARM9 return trampoline, and continue.  Thus FP1 and FP2 are
// peers in one second-stage program, rather than two unrelated loaders.
//
// P3 is separate from this immediate two-CPU hand-off.  Its changes bypass the
// retail verification paths that would reject the modified firmware contents;
// P4 and P5 are retained unchanged.  H and FH are both based on the original
// H, but H describes primary P1/P2 whereas FH describes FP1/FP2.  dsfwtool
// supplies their calculated component locations and CRCs during packing.
// FlashMe-owned H/FH +0x17C stores the type marker.  Public-image
// reconstruction blanks copied Wi-Fi fields and fixes +0x17E to FFFF.
//
// The chronological outline stays in plain text; each component file appends one
// comment-only C flow model after its assembly implementation.
//
//     boot loader: starts H:P1 on ARM9 || H:P2 on ARM7
//     P1:          waits by repeatedly branching through P1 +0x0C
//     P2:          selects a route, optionally reads FH and loads FP1/FP2,
//                  then overwrites P1 +0x0C to release ARM9
//     FP1 || FP2:  run as the second pair; FP2 publishes B/C then D, and FP1
//                  consumes that phase before retained retail code continues
//
// =============================================================================
// 作为完整程序的引导时序（中文）
// =============================================================================
//
// 这是一套双 CPU 的 NDS 引导程序，而不是一条线性的 C 函数调用链。零售引导环境会
// 独立启动固件头所描述的 ARM9 与 ARM7 组件；FlashMe 有意把它变成前后相接的两对
// ARM9/ARM7 程序：
//
//     一级头 H
//       |- ARM9：P1，位于 PrimaryP1RamAddress 的等待闸门
//       `- ARM7：P2，位于 PrimaryP2RamAddress 的一级协调器
//                         |
//                         | 读取并解释 FH
//                         v
//     二级头 FH，在本布局中位于镜像 +0x3FC80
//       |- ARM9：FP1 前置代码 + 保留的零售 P1
//       `- ARM7：FP2 前置代码 + 保留的零售 P2
//
// 第一阶段从正常固件加载器解释 H 时开始。H 只描述体积很小的替换 P1 与 P2，并不
// 直接描述零售 P1/P2 主体。ARM9 的 P1 短桩先完成继承自零售流程的寄存器写入，然后
// 反复读取可修改的 P1 +0x0C 字面量字。该字的初始值正是 P1 +4，因此 ARM9 会刻意
// 停在 LDR/BX 循环中，等待 ARM7 的 P2 工作完成。也就是说，P1 并不是由 P2 在稍后
// 以普通子函数形式调用的代码；两颗 CPU 从一开始就已并行执行。
//
// 一级 P2 是第一对程序的协调器。它会把零售引导 ABI 传入的 r12 值保留为头工作区
// 指针；必要时根据按键与 Slot-2/AGB 标题检查选择兼容分支，其他情况下则通过 ARM7
// BIOS 的固件读取与 LZ77 路径加载 FH 所描述的两个组件。它用 shift_amounts 解释
// 描述符单位，因此 FH 中的 RAM 地址会选定 FP1 与 FP2。当这些工作产生 ARM9 的续接
// 地址后，P2 将其写入 P1 +0x0C。P1 等待循环的下一次迭代便会离开闸门，进入已加载
// 的 ARM9 二级路径。兼容分支也使用同一个放行槽，但会先为既有返回流程构造一个小型
// ARM9 跳板。patch_p1.s 与 patch_p2.s 分别是这次握手的 ARM9 与 ARM7 两半。
//
// 第二阶段是由 FH 描述的 FP1/FP2 对。每个组件都由新的 FlashMePrefixBytes 字节前置代码
// 和被包含的零售主体组成。汇编会从源 H 解码零售运行入口，并以
// `RetailP?RamAddress - FlashMePrefixBytes` 动态推导 FP1/FP2；不会把固定入口地址
// 写死在补丁中。因此前置代码只是添加在原始入口之前，并没有搬移零售主体，也不会破坏其
// 对绝对地址的假设。
// 本补丁会把一级 P1 闸门放在该零售 ARM9 区域正下方的 64 KiB 页内，并把一级 P2 推导为
// P2 格式基址减去 2 KiB 暂存窗口；这两项是明确的布局规则，而不是源 H 中的字段。
//
// FP2 是第二对中的 ARM7 成员，它发布由 ARM9 侧 FP1 消费的 IPC 阶段值。从 ARM9 所见
// 的低半字节看，0xB 选择保留 P1/P2，0xC 选择 FlashMe 专用冷启动路径，0xD 是常规 V4
// 的会合点。BuildStealth=0 时，FP2 会在 B 后执行服务时序并发布 D，FP1 会等到 D 后才
// 进入保留 P1；BuildStealth=1 时，两个前置代码都会将 B 路径直接转入各自保留主体。C
// 路径中，两种变体都会完成冷启动所需的 ARM7/ARM9 准备，在 D 会合、安装 ARM9 返回跳板
// 后继续。因此 FP1 和 FP2 是同一套二级程序中互相配合的两个成员，而不是互不相关的两个
// 加载器。
//
// P3 不属于这次即时的双 CPU 交接。对它的修改会绕过原本会拒绝改写后固件内容的零售
// 验证路径；P4 与 P5 保持原样。H 与 FH 都以原始 H 为基础：H 描述一级 P1/P2，FH
// 描述 FP1/FP2；打包时由 dsfwtool 填入重新计算的组件位置与 CRC。FlashMe 自有的
// H/FH +0x17C 保存类型标记。公开镜像重构会清空复制来的 Wi-Fi 字段，并将
// +0x17E 固定为 FFFF。
//
// 以下时间纲要保持普通文字；每个组件文件都会在其汇编实现后附上一份仅作注释的 C 流程模型。
//
//     固件加载器：在 ARM9 启动 H:P1，同时在 ARM7 启动 H:P2
//     P1：         反复经由 P1 +0x0C 跳转，处于等待状态
//     P2：         选择路径；适用时读取 FH 并加载 FP1/FP2；随后覆写 P1 +0x0C，
//                 放行 ARM9
//     FP1 || FP2：作为第二对程序运行；FP2 发布 B/C 后再发布 D，FP1 消费该阶段，
//                 然后保留的零售代码继续执行

.nds

.include "include/symbol.inc"
.include "src/patch_h.s"
.include "src/patch_p1.s"
.include "src/patch_p2.s"
.include "src/patch_p3.s"
.include "src/patch_p4.s"
.include "src/patch_p5.s"
.include "src/patch_fh.s"
.include "src/patch_fp1.s"
.include "src/patch_fp2.s"
