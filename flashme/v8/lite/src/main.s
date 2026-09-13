.nds

; Runtime ownership: P1/FP1 are boot9 (ARM9); P2/FP2 are boot7 (ARM7); P3 is ARM9 GUI; P4 is ARM7 Wi-Fi; P5 is graphics/data.
; 运行归属：P1/FP1 为 boot9（ARM9）；P2/FP2 为 boot7（ARM7）；P3 为 ARM9 GUI；P4 为 ARM7 Wi-Fi；P5 为图形/数据。

; Symbol layers: NDS common state, Nintendo base-firmware state, then FlashMe-local state.
; 符号层：NDS 通用状态、任天堂基础固件状态，最后是 FlashMe 本地状态。
.include "../../../include/common.inc"
.include "../../../include/official_v6_sym.inc"
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
