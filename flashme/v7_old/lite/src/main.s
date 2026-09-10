// FlashMe V7 Old Lite Beta armips patch entry point.
//
// =============================================================================
// Whole-program boot model (English)
// =============================================================================
//
// This project starts with official Nintendo DS firmware V6.  It is the Lite
// base rule for this patch family; Phat projects start with official V3 instead.
// A FlashMe template is used only as a comparison target, never as a build input.
//
// The DS firmware loader starts H:P1 on ARM9 and H:P2 on ARM7 concurrently.
// FlashMe turns that initial pair into a small first-stage coordinator:
//
//     H (primary header)
//       ARM9 P1: parking gate at PrimaryP1RamAddress
//       ARM7 P2: reads FH, selects a route, and releases P1 through P1 + 0x08
//                                  |
//                                  v
//     FH (secondary header at image + 0x3F680)
//       ARM9 FP1: V7 prefix + retained official V6 P1
//       ARM7 FP2: V7 Lite prefix + retained official V6 P2
//
// P1 begins with an LDR/BX loop whose mutable word initially points to P1
// itself.  P2 either follows the inherited service path or loads the FH pair,
// then overwrites that word with the ARM9 continuation.  This is shared-memory
// synchronization between two already-running CPUs, not a later subroutine call.
//
// FP2 owns second-stage route selection.  It publishes IPC low-nibble B for
// the retained service route and C for FlashMe cold preparation.  Normal V7 Old
// performs its service timing after B and publishes E; Stealth returns to the
// retained bodies immediately on B.  Both C routes prepare their CPU-visible
// state and rendezvous at E.  Lite additionally runs its observed two-step SPI
// configuration before the final peripheral commands.  FP1 consumes the same
// B/C/E protocol and installs the ARM9 return trampoline for the cold route.
//
// Each FP prefix is 0x400 bytes.  symbol.inc decodes the retail runtime entry
// from the original H and subtracts that prefix size, so the included retail
// P1/P2 bodies still start at their native RAM addresses.  H and FH both start
// as copies of the official header: H describes primary P1/P2, FH describes
// FP1/FP2.  dsfwtool calculates component locations and CRCs while packing.
//
// P3 supplies the later signature/hash compatibility changes.  P4 and P5 are
// retained retail components.  The source files below emit plaintext components;
// the Makefile invokes dsfwtool for compression, encryption, physical placement,
// and preservation of the base firmware settings area.
//
// =============================================================================
// 完整程序引导模型（中文）
// =============================================================================
//
// 本工程以官方 Nintendo DS V6 固件为起点。这是本补丁族的 Lite 母版规则；Phat 工程
// 则以官方 V3 为起点。FlashMe 模板只作为比对目标，绝不作为构建输入。
//
// DS 固件加载器会并行启动 H:P1（ARM9）与 H:P2（ARM7）。FlashMe 将这一对初始组件
// 转变为一个很小的一级协调器：
//
//     H（一级头）
//       ARM9 P1：位于 PrimaryP1RamAddress 的等待闸门
//       ARM7 P2：读取 FH、选择路径，并通过 P1 + 0x08 放行 P1
//                                  |
//                                  v
//     FH（位于镜像 + 0x3F680 的二级头）
//       ARM9 FP1：V7 前置代码 + 保留的官方 V6 P1
//       ARM7 FP2：V7 Lite 前置代码 + 保留的官方 V6 P2
//
// P1 从一段 LDR/BX 循环开始；其可修改字初始指向 P1 自己。P2 会选择继承服务路径，
// 或加载 FH 所述组件对，随后把 ARM9 续接地址写入该字。这是两颗已在运行的 CPU 之间
// 的共享内存同步，而非稍后才发生的子函数调用。
//
// FP2 负责二级路径选择。它用 IPC 低四位的 B 表示保留服务路径、C 表示 FlashMe 冷启动
// 准备。常规 V7 Old 会在 B 后执行服务时序并发布 E；Stealth 会在 B 路径立即进入保留
// 主体。两种 C 路径均会准备各自 CPU 可见的状态并在 E 会合。Lite 还会在最终外设命令
// 前执行观察到的两步 SPI 配置。FP1 消费相同的 B/C/E 协议，并为冷启动路径安装 ARM9
// 返回跳板。
//
// 每个 FP 前置区为 0x400 字节。symbol.inc 会从原始 H 解码零售运行入口并减去此前置区
// 长度，因此被包含的零售 P1/P2 主体仍从原生 RAM 地址开始。H 与 FH 都从官方头复制而
// 来：H 描述一级 P1/P2，FH 描述 FP1/FP2。打包时 dsfwtool 计算组件地址与 CRC。
//
// P3 提供后续签名/哈希兼容修改；P4 与 P5 保留为零售组件。下列源文件生成明文组件；
// Makefile 调用 dsfwtool 完成压缩、加密、物理放置及基底固件设置区保留。

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
