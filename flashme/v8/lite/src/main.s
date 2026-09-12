// FlashMe V8 Lite armips patch entry point.
//
// =============================================================================
// Whole-program boot model (English)
// =============================================================================
//
// This project starts only from official_v6.bin, the Lite base
// for this patch family. A FlashMe V8 image is a comparison target, never a
// build input.
//
// The firmware loader starts H:P1 on ARM9 and H:P2 on ARM7 concurrently:
//
//     H (primary header)
//       ARM9 P1: mutable LDR/BX parking gate
//       ARM7 P2: selects a route and releases P1 through P1 + 0x08
//                                  |
//                                  v
//     FH (secondary header at image + 0x3F680)
//       ARM9 FP1: V8 prefix + retained P1 from official_v6.bin
//       ARM7 FP2: V8 Lite prefix + retained P2 from official_v6.bin
//
// P2 either follows the inherited service path or loads the FH pair, then
// overwrites P1's mutable word with the selected ARM9 continuation. This is
// shared-RAM synchronization between CPUs that are already executing, rather
// than a conventional later subroutine call.
//
// FP2 owns second-stage route selection and uses IPC low nibbles B, C, and E.
// Normal and Stealth retain Select, A+B+X+Y, and DSBooter/PASS title routing;
// NoAuto variants accept only A+B+X+Y, while preserving unreachable title-test
// bytes for their official layouts. The B route copies FH. Normal Lite uses its
// observed BIOS loop delay before E; Stealth enters retained bodies immediately.
// Every C route clears DMA, copies FH, runs Lite's two-step SPI preparation,
// performs the BIOS hand-off, sends final SPI commands, and rendezvous with FP1
// at E.
//
// Every FP prefix is 0x400 bytes. symbol.inc derives its address from the
// retail entry decoded from the source H, so retained P1/P2 still begin at their
// native RAM addresses. H names primary P1/P2 and FH names FP1/FP2; dsfwtool
// calculates locations and CRCs during packing. P3 supplies the later
// signature/hash compatibility changes, while P4/P5 remain retail components.
//
// =============================================================================
// 完整程序引导模型（中文）
// =============================================================================
//
// 本工程只以 official_v6.bin 为起点，它是该补丁族的 Lite 母版。FlashMe V8
// 镜像仅作比对目标，绝不作为构建输入。
//
// 固件加载器会并行启动 H:P1（ARM9）与 H:P2（ARM7）：
//
//     H（一级头）
//       ARM9 P1：可修改的 LDR/BX 等待闸门
//       ARM7 P2：选择路径，并通过 P1 + 0x08 放行 P1
//                                  |
//                                  v
//     FH（位于镜像 + 0x3F680 的二级头）
//       ARM9 FP1：V8 前置代码 + 保留的官方 V6 P1
//       ARM7 FP2：V8 Lite 前置代码 + 保留的官方 V6 P2
//
// P2 会选择继承服务路径或加载 FH 所述组件对，随后把 P1 的可修改字改写为选定的 ARM9
// 续接地址。这是两颗已经在运行的 CPU 之间通过共享 RAM 实现的同步，而不是后来发生的
// 常规子函数调用。
//
// FP2 拥有二级路径选择权，并使用 IPC 低四位的 B、C、E。常规与 Stealth 保留 Select、
// A+B+X+Y 和 DSBooter/PASS 标题的路径选择；NoAuto 只接受 A+B+X+Y，同时为保持官方
// 布局而保留不可达标题测试字节。B 路径复制 FH。常规 Lite 会在 E 前使用观测到的 BIOS
// 循环延时；Stealth 则立即进入保留主体。每种 C 路径都会清除 DMA、复制 FH、执行 Lite
// 两步 SPI 准备、进行 BIOS 交接、发送最终 SPI 命令，再在 E 与 FP1 会合。
//
// 每个 FP 前置区均为 0x400 字节。symbol.inc 会从源 H 解码零售入口后推导其地址，因此
// 保留的 P1/P2 仍从原生 RAM 地址开始。H 指向一级 P1/P2，FH 指向 FP1/FP2；dsfwtool 在
// 打包时计算位置与 CRC。P3 提供后续签名/哈希兼容修改，P4/P5 则保留为零售组件。

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
