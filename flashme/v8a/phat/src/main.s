// FlashMe V8a Phat reconstruction entry point.
//
// Build flow: official_v3.bin is unpacked into plaintext temp/, armips
// recreates only the changed components in build/, then dsfwtool recalculates
// component descriptors and assembles the FlashMe image.  No FlashMe template
// is read during this build.
//
// 构建流程：先把官方 V3 镜像解包为明文 temp/，armips 只在 build/ 中重建已改动组件，
// 最后由 dsfwtool 重算组件描述符并拼装 FlashMe 镜像。构建过程中不会读取 FlashMe 模板。
//
// H starts the Phat P1/P2 pair.  P2 owns the first-stage route and command word;
// FH describes the Phat FP1 and FP2 pair, each followed by retained
// bodies from official_v3.bin. P3 bypasses the later signature/hash checks; P4/P5 are
// preserved retail components.
//
// H 启动 Phat P1/P2 对。P2 掌握一级路径和命令字；FH 描述 Phat FP1 与 FP2，
// 二者后方均接保留的官方 V3 主体。P3 绕过后续签名/哈希检查；P4/P5 保持零售组件。
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
