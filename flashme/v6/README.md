# FlashMe V6 Phat armips reconstruction

This project rebuilds the normal and Stealth FlashMe V6 Phat layouts from one
armips source tree.  Its source firmware is always official NTR Firmware V3:
the retained P1/P2/P3/P4/P5 bodies and the initial H header come from V3.
FlashMe template images are analysis references only and are not build inputs.

The base-firmware rule is intentionally explicit for the whole reconstruction
set: Phat projects use official V3, while Lite projects use official V6.

## Layout

```text
official_v3.bin          official V3 input firmware
Makefile                 build entry point
include/symbol.inc       platform constants and V6 layout definitions
src/main.s               armips entry point and dual-CPU boot-map commentary
src/patch_h.s            primary header H
src/patch_p1.s ...       primary P1--P5 components
src/patch_fh.s           secondary FlashMe header FH
src/patch_fp1.s ...      secondary FP1 and FP2 components
temp/                    plaintext H and P1--P5 extracted from official V3
build/                   armips-generated plaintext H/P1--P5/FH/FP1/FP2
flashme_v6_phat.bin      normal output image
flashme_v6_stealth_phat.bin
                          Stealth output image
```

Only plaintext components are kept in `temp/` and `build/`.  The final
`dsfwtool` call performs P1/P2 compression and encryption, P345 compression,
FP1/FP2 compression, component padding, component CRC calculation, and H/FH
address updates.

## Prerequisites

- `official_v3.bin`, the official V3 firmware, in this directory;
- `../armips.exe`;
- `../dsfwtool.exe` with `--p345-nearest-greedy` support.

`OFFICIAL_V3`, `ARMIPS`, and `DSFWTOOL` can be overridden on the make command
line when those files are stored elsewhere.

## Build

Build the normal Phat image:

```bat
make
```

Build the Stealth Phat image:

```bat
make VARIANT=stealth
```

Build both variants:

```bat
make variants
```

## V6 component model

H describes a compact primary P1/P2 pair.  P1 is an ARM9 parking gate and P2
is the ARM7 coordinator which selects the route, reads FH when appropriate,
and releases P1 through its mutable continuation word.

FH describes the secondary FP1/FP2 pair.  Each FP component begins with a
0x200-byte FlashMe prefix and then includes the official V3 P1 or P2 body at
its original RAM entry.  FP2 publishes B/C/D IPC phases and FP1 responds on
ARM9.  The normal and Stealth variants share retained bodies but select
different B-route behavior.

V6 sets `shift_amounts` to `0x0C71`, so components use 8-byte descriptor
alignment.  The primary H marker is `2`, while the secondary FH marker is `3`.
The primary P1/P2 CRC16 from the V3 source header is retained at `+0x17E` in
both headers as FlashMe's source-firmware marker.

The Makefile pins the historical V6 Phat physical layout:

| Component | Offset |
| --- | ---: |
| P1 | `0x000180` |
| P2 | `0x000198` |
| P5 | `0x0002B8` |
| P4 | `0x00F5A8` |
| P3 | `0x0183A8` |
| FP2 | `0x029FA0` |
| FP1 normal | `0x0323D8` |
| FP1 Stealth | `0x032390` |
| FH | `0x03F680` |

P3--P5 use the compact nearest-distance, no-delay P345 mode needed by this
FlashMe layout.  This is deliberately scoped to this build command; it does
not change dsfwtool's default official-firmware P345 reconstruction mode.

---

# FlashMe V6 Phat 的 armips 重建工程

本工程通过同一套 armips 源码重建 FlashMe V6 Phat 的常规版与 Stealth 版。它的源
固件始终是官方 NTR Firmware V3：保留的 P1/P2/P3/P4/P5 主体以及起始 H 头均来自
V3。FlashMe 模板镜像仅用于分析，不是构建输入。

整套重建工程明确遵循同一条母版规则：Phat 工程使用官方 V3，Lite 工程使用官方 V6。

## 目录结构

```text
official_v3.bin          官方 V3 输入固件
Makefile                 构建入口
include/symbol.inc       平台常量与 V6 布局定义
src/main.s               armips 入口及双 CPU 引导图说明
src/patch_h.s            一级头 H
src/patch_p1.s ...       一级 P1--P5 组件
src/patch_fh.s           二级 FlashMe 头 FH
src/patch_fp1.s ...      二级 FP1 与 FP2 组件
temp/                    从官方 V3 导出的明文 H 与 P1--P5
build/                   armips 生成的明文 H/P1--P5/FH/FP1/FP2
flashme_v6_phat.bin      常规版输出镜像
flashme_v6_stealth_phat.bin
                          Stealth 版输出镜像
```

`temp/` 与 `build/` 只保存明文组件。最后的 `dsfwtool` 调用会完成 P1/P2 的压缩和
加密、P345 压缩、FP1/FP2 压缩、组件填充、组件 CRC 计算，以及 H/FH 地址更新。

## 前置文件

- 本目录中的官方 V3 固件 `official_v3.bin`；
- `../armips.exe`；
- 支持 `--p345-nearest-greedy` 的 `../dsfwtool.exe`。

若这些文件位于其他位置，可在 make 命令行覆写 `OFFICIAL_V3`、`ARMIPS` 和
`DSFWTOOL`。

## 构建

构建常规 Phat 镜像：

```bat
make
```

构建 Stealth Phat 镜像：

```bat
make VARIANT=stealth
```

一次构建两个变体：

```bat
make variants
```

## V6 组件模型

H 描述一对紧凑的一级 P1/P2。P1 是 ARM9 等待闸门；P2 是 ARM7 协调器，负责选择路径、
适用时读取 FH，并通过可修改的续接字放行 P1。

FH 描述二级 FP1/FP2。每个 FP 组件由一个 0x200 字节的 FlashMe 前置代码和位于原始
RAM 入口的官方 V3 P1 或 P2 主体组成。FP2 发布 B/C/D IPC 阶段，FP1 在 ARM9 上响应。
常规版与 Stealth 版共享保留主体，但在 B 路径上采用不同的行为。

V6 将 `shift_amounts` 设为 `0x0C71`，因此组件描述符采用 8 字节对齐。一级 H 标记为
`2`，二级 FH 标记为 `3`。源 V3 头中的一级 P1/P2 CRC16 会保存在两份头的 `+0x17E`，
作为 FlashMe 的来源固件标记。

Makefile 固定 V6 Phat 的历史物理布局：

| 组件 | 偏移 |
| --- | ---: |
| P1 | `0x000180` |
| P2 | `0x000198` |
| P5 | `0x0002B8` |
| P4 | `0x00F5A8` |
| P3 | `0x0183A8` |
| FP2 | `0x029FA0` |
| FP1 常规版 | `0x0323D8` |
| FP1 Stealth | `0x032390` |
| FH | `0x03F680` |

P3--P5 使用该 FlashMe 布局所需的紧凑 P345 最近距离、无延迟模式。该选择只作用于本
构建命令，不会改变 dsfwtool 默认的官方固件 P345 重建模式。
