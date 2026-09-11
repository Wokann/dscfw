// FlashMe V8a Lite reconstruction entry point.
//
// H starts the Lite P1/P2 pair.  P2 owns the first-stage route and command
// word; FH describes the Lite FP1/FP2 pair, each followed by retained official
// V6 code.  P3 contains the later verification compatibility modifications;
// P4/P5 remain retail components.
//
// H 启动 Lite P1/P2 对。P2 掌握一级路径和命令字；FH 描述 Lite FP1/FP2 对，
// 二者后方均接保留的官方 V6 代码。P3 包含后续验证兼容修改；P4/P5 保持零售组件。
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
