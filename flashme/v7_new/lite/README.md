# FlashMe V7 New Lite armips reconstruction

This project rebuilds the normal and Stealth Lite variants of FlashMe V7 New.
Its only firmware build input is official Nintendo DS firmware V6. The
FlashMe image is an analysis reference, not an input to the build.

## Files and prerequisites

- Put official V6 firmware in this directory as official_v6.bin.
- ../../armips.exe must be the armips assembler.
- ../../dsfwtool.exe must support FlashMe components and P345 `-comp -flashme`.

temp/ receives plaintext H and P1--P5 extracted from official V6. armips writes
plaintext replacement components to build/. The Makefile gives those components
to dsfwtool, which recalculates header/component metadata, compresses and
encrypts where appropriate, and preserves the settings region from V6.

## Build

Build the normal image:

    make VARIANT=normal

Build the Stealth image:

    make VARIANT=stealth

Build both:

    make variants

The generated images are flashme_v7_new_lite.bin and
flashme_v7_new_stealth_lite.bin.

## Component model

H describes a small primary P1/P2 pair. P1 parks ARM9 in a mutable LDR/BX gate
while P2 reads FH and releases it. FH describes FP1/FP2, the second ARM9/ARM7
pair. Each FP component is a 0x400-byte V7 New prefix followed by the retained
official V6 body at its original decoded RAM entry.

FP2 selects the second-stage route and publishes IPC phases B, C, and E. B
returns to the retained service route; normal builds perform their historical
service timing before E, while Stealth enters directly. C performs FlashMe cold
preparation, including Lite's two-step SPI configuration, and FP1/FP2 rendezvous
at E. P3 contains the later signature/hash compatibility edits; P4/P5 retain
official code.

The Makefile fixes the historical V7 New Lite component placement:

| Component | ROM offset |
| --- | ---: |
| P1 / P2 / P5 | 0x180 / 0x198 / 0x2B8 |
| P4 / P3 | 0x0F5A8 / 0x183B8 |
| FP2 | 0x29FE8 |
| FP1 normal / Stealth | 0x32738 / 0x326F8 |
| FH | 0x3F680 |

---

# FlashMe V7 New Lite 的 armips 重建工程

本工程用于重建 FlashMe V7 New 的 Lite 常规版和 Stealth 版。唯一的固件构建输入是
官方 Nintendo DS V6；FlashMe 镜像只作为分析参照，不参与构建输入。

## 文件与前提条件

- 将官方 V6 固件放在本目录并命名为 official_v6.bin。
- ../../armips.exe 应为 armips 汇编器。
- ../../dsfwtool.exe 应支持 FlashMe 组件及 P345 命令形式 `-comp -flashme`。

temp/ 保存从官方 V6 提取的 H 和 P1--P5 明文。armips 将替换组件的明文写入 build/。
Makefile 再把这些组件交给 dsfwtool，由它重算头/组件元数据、按需压缩与加密，并从 V6
保留设置区。

## 构建

构建常规版：

    make VARIANT=normal

构建 Stealth 版：

    make VARIANT=stealth

同时构建两种版本：

    make variants

输出文件为 flashme_v7_new_lite.bin 和
flashme_v7_new_stealth_lite.bin。

## 组件模型

H 描述小型一级 P1/P2 对。P1 通过可修改的 LDR/BX 闸门停驻 ARM9，P2 读取 FH 后
放行它。FH 描述作为第二套 ARM9/ARM7 对的 FP1/FP2。每个 FP 组件均由 0x400 字节
V7 New 前置代码和仍位于原始解码 RAM 入口的官方 V6 主体组成。

FP2 选择第二阶段路径，并发布 IPC 阶段 B、C、E。B 返回保留服务路径；常规版会在
进入 E 前执行其历史服务时序，Stealth 则直接进入。C 进行 FlashMe 冷启动准备，
包括 Lite 的两步 SPI 配置，FP1/FP2 会在 E 会合。P3 含后续签名/哈希兼容修改；
P4/P5 保留官方代码。

Makefile 固定 V7 New Lite 的历史组件放置：

| 组件 | ROM 偏移 |
| --- | ---: |
| P1 / P2 / P5 | 0x180 / 0x198 / 0x2B8 |
| P4 / P3 | 0x0F5A8 / 0x183B8 |
| FP2 | 0x29FE8 |
| FP1 常规 / Stealth | 0x32738 / 0x326F8 |
| FH | 0x3F680 |
