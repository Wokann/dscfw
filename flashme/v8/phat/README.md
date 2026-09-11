# FlashMe V8 Phat armips reconstruction

This project rebuilds all four FlashMe V8 Phat variants from official Nintendo
DS firmware V3. The build input is only `official_v3.bin`; a FlashMe image may
be used to compare the result, but it is never an input to the reconstruction.

## Prerequisites and generated directories

- Place the official V3 firmware beside this file as `official_v3.bin`.
- `../../armips.exe` must be the armips assembler.
- `../../dsfwtool.exe` must support FlashMe components and
  `--p345-nearest-greedy`.

`temp/` receives plaintext H and P1–P5 extracted from V3. armips creates
plaintext replacement components in `build/`. dsfwtool then recalculates the
header and component metadata, compresses/encrypts applicable components,
places them at the historical V8 offsets, and preserves V3's settings area.

## Build

```sh
make VARIANT=normal
make VARIANT=stealth
make VARIANT=noauto
make VARIANT=stealth-noauto
make variants
```

The output names are:

- `flashme_v8_phat.bin`
- `flashme_v8_stealth_phat.bin`
- `flashme_v8_noauto_phat.bin`
- `flashme_v8_stealth_noauto_phat.bin`

`normal` and `stealth` retain V8's automatic route selection: Select chooses
the service path, A+B+X+Y chooses FlashMe, and the Slot-2 DSBooter/PASS title
is an additional FlashMe trigger. `noauto` variants accept only the A+B+X+Y
chord; the retained title-test bytes remain in the prefix but are unreachable.
Normal uses the Phat service timing sequence, while Stealth returns directly to
the retained service bodies.

## Component model and fixed placement

H starts a small primary P1/P2 pair. P1 parks ARM9 in a mutable LDR/BX gate;
P2 selects the inherited or FlashMe path and releases it. FH describes FP1 and
FP2. Each FP component has a 0x400-byte V8 prefix followed by the retained
official V3 body at its original decoded RAM entry. FP2 publishes IPC phases
B, C, and E; FP1 consumes them to prepare ARM9 only for the cold path. V8 Phat
retains old auxiliary and two-step SPI helper blocks for binary layout, but its
active cold path sends only the final SPI commands.

| Component | ROM offset |
| --- | ---: |
| P1 / P2 / P5 | 0x180 / 0x198 / 0x2B8 |
| P4 / P3 | 0x0F5A8 / 0x183A8 |
| FP2 | 0x29FA0 |
| FP1 normal / Stealth / NoAuto / Stealth-NoAuto | 0x324C0 / 0x32480 / 0x324B8 / 0x32478 |
| FH | 0x3F680 |

---

# FlashMe V8 Phat 的 armips 重建工程

本工程从官方 Nintendo DS V3 固件重建全部四种 FlashMe V8 Phat 变体。构建输入只有
`official_v3.bin`；FlashMe 镜像可以用于比对结果，但绝不参与重建输入。

## 前提条件与生成目录

- 将官方 V3 固件放在本文件同级目录，命名为 `official_v3.bin`。
- `../../armips.exe` 必须为 armips 汇编器。
- `../../dsfwtool.exe` 必须支持 FlashMe 组件以及 `--p345-nearest-greedy`。

`temp/` 保存从 V3 提取出的 H 和 P1–P5 明文。armips 在 `build/` 生成替换组件的明文。
随后 dsfwtool 会重算头与组件元数据、按需压缩/加密、放置到历史 V8 偏移，并保留 V3 的
设置区。

## 构建

```sh
make VARIANT=normal
make VARIANT=stealth
make VARIANT=noauto
make VARIANT=stealth-noauto
make variants
```

输出文件为：

- `flashme_v8_phat.bin`
- `flashme_v8_stealth_phat.bin`
- `flashme_v8_noauto_phat.bin`
- `flashme_v8_stealth_noauto_phat.bin`

`normal` 与 `stealth` 保留 V8 的自动路径选择：Select 选择服务路径，A+B+X+Y 选择
FlashMe，Slot-2 的 DSBooter/PASS 标题也是额外的 FlashMe 触发器。`noauto` 变体只接受
A+B+X+Y 组合；保留的标题测试字节仍存在于前置区中，但不可达。常规版使用 Phat 服务
时序，Stealth 则直接回到保留的服务主体。

## 组件模型与固定放置

H 会启动小型一级 P1/P2 对。P1 通过可修改的 LDR/BX 闸门停驻 ARM9；P2 选择继承或
FlashMe 路径并放行它。FH 描述 FP1 与 FP2。每个 FP 组件均由 0x400 字节的 V8 前置代码
以及仍位于原始解码 RAM 入口的官方 V3 主体组成。FP2 发布 IPC 阶段 B、C、E；FP1 消费
它们，只在冷路径准备 ARM9。V8 Phat 为保持二进制布局而保留旧辅助卡与两步 SPI 帮助块，
但其实际冷路径只发送最终 SPI 命令。

| 组件 | ROM 偏移 |
| --- | ---: |
| P1 / P2 / P5 | 0x180 / 0x198 / 0x2B8 |
| P4 / P3 | 0x0F5A8 / 0x183A8 |
| FP2 | 0x29FA0 |
| FP1 常规 / Stealth / NoAuto / Stealth-NoAuto | 0x324C0 / 0x32480 / 0x324B8 / 0x32478 |
| FH | 0x3F680 |
