# FlashMe V2 推断性 armips 重建

> **不是找回的历史镜像。** 当前没有可用的原始 FlashMe V2 载荷作为二进制参考；本目录是以已知 FlashMe V1 与 V3 Phat 载荷、以及同期论坛变更记录为依据的功能性模拟重建。输出刻意命名为 `flashme_v2_inferred.bin`，不得称作原始 V2 或逐字节还原结果。

This is an **inferred functional reconstruction**, not a recovered historical FlashMe V2 image.  It uses the known FlashMe V1/V3 Phat payloads and contemporaneous forum records; the output is deliberately named `flashme_v2_inferred.bin` and must not be presented as an original V2 binary or a byte-identical reproduction.

本目录以 Nintendo NTR Firmware V3 作为零售组件输入，但行为构造统一以 V1 为基线：主头、一级组件、FP1/FP2 载荷、P3--P5，以及 `P3 -> FP1 -> FP2` 的物理排列顺序均采用 V1。仅在保留的 ARM9 P1 中加入两处明确标为“推断”的状态机改动，以模拟 V2 报告的“直接启动 `.ds.gba` 时移除健康警告”功能。

The Nintendo NTR Firmware V3 input supplies the retail components, while V1 consistently supplies the behavioral baseline: the primary header, primary components, FP1/FP2 payloads, P3--P5, and the physical `P3 -> FP1 -> FP2` order all follow V1.  Only two explicitly marked *inferred* retained-ARM9 state-machine edits are added to model V2's reported omission of the health-warning path during direct `.ds.gba` boot.

## 目录结构

```text
official_v3.bin       官方 V3 输入固件
Makefile              构建入口
include/symbol.inc    共享定义
src/main.s            armips 入口，包含全部组件补丁
src/patch_h.s         主固件头 H
src/patch_p1.s ...    P1--P5
src/patch_fh.s        FlashMe 头 FH
src/patch_fp1.s ...   FP1、FP2
temp/                 从官方 V3 直接导出的明文 H、P1--P5
build/                armips 生成的明文 H、P1--P5、FH、FP1、FP2
flashme_v2_inferred.bin
                       推断性重建的最终打包镜像；不是历史 V2 原件
```

`temp/` 和 `build/` 中只存放明文组件。压缩、P1/P2 加密、组件对齐、头部偏移及校验更新全部由最后的 `dsfwtool` 打包命令处理。

## 前置文件

本目录需要：

- `official_v3.bin`：官方 NTR Firmware V3；
- `../armips.exe`：armips；
- `../dsfwtool.exe`：dsfwtool。

默认布局已将两个工具放在 `v2` 的父目录。若官方固件位于其他位置，可在调用时覆写 `OFFICIAL_V3`，例如：

```bat
make OFFICIAL_V3=D:/firmware/official_v3.bin
```

## 构建

在本目录运行：

```bat
make
```

`Makefile` 依次执行：

1. 使用 `dsfwtool -x` 将官方 V3 导出为 `temp/` 内的解密、解压明文组件；
2. 使用 `armips` 执行 `src/main.s`，在 `build/` 生成 FlashMe V2 的明文组件；
3. 使用 `dsfwtool -c` 对 P1/P2 压缩并加密、对 P3--P5/FP1/FP2 压缩，并在 `0x3FC80` 写入 FH，生成根目录的 `flashme_v2_inferred.bin`。

## 组件构造

- H、P1、P2、FH：由 armips 源码直接生成，使用 V1 的头部规则与布局。
- FP1：`0x200` 字节 FlashMe ARM9 前缀，加上零售 P1；保留 V1 的两处回调修改，并额外施加两处**推断性** V2 状态机修改：`+0x2DC` 的状态表项与 `+0x8CE` 的跳转。
- FP2：`0x200` 字节 FlashMe ARM7 前缀，加上零售 P2；保持 V1 的完整 `DSBooterPASSFLSH` 签名与寄存器布局。
- P3：以官方 P3 为基础进行三处局部 Thumb 补丁。
- P4、P5：直接保留官方 V3 的明文内容。

## V2 的推断边界

保留零售 P1 的 `+0x2DC` 是状态 0 的跳转表数据。V1 的 `0x0017` 会进入已有的 `+0x0AAC` 路径；本重建写入 V3 已使用的 `0x0023`，使其改进已有的 `+0x0884` 路径。`+0x8CE` 的无条件跳转则改为 NOP，以便该路径进入已有状态处理。此二者是为模拟健康警告跳过而选择的最小改动集合。

V3 在 `+0x89E`、`+0x8BA` 还把两个 `0x0F` 计时门改成 `1`。本重建刻意保留 V1 的 `0x0F`，不把 V3 的缩短显示/渐变时序带入；同时保留 V1 的 FP2、P3 和 WMB/RSA 行为，不模拟 V3 的额外策略变化。

已知 FlashMe V1、V3 Phat 镜像的 `0x00000--0x0FFFF` 完全相同。本工程沿用同一保护区，并采用**V1 的排列顺序** `P3 -> FP1 -> FP2`。ROM 地址不是固定魔数：`align8(0x183B0 + 0x11BF7) = 0x29FA8` 放置 FP1；FP1 的有效压缩流为 `0xCB1B`，所以 `align8(0x29FA8 + 0xCB1B) = 0x36AC8` 放置 FP2。Makefile 故意不指定 FP1/FP2 的 `--offset`，由 `dsfwtool` 按此 V1 顺序重新计算，避免将压缩流长度误当成固定不变。原始 V2 载荷缺失，这仍是本工程的明确 V1 基线选择，而不是历史 V2 镜像证据。

Known FlashMe V1 and V3 Phat images have identical `0x00000--0x0FFFF` regions, and this project retains that protected region while choosing **V1's ordering**, `P3 -> FP1 -> FP2`.  ROM addresses are not fixed magic constants: `align8(0x183B0 + 0x11BF7) = 0x29FA8` places FP1; FP1's effective compressed stream is `0xCB1B`, so `align8(0x29FA8 + 0xCB1B) = 0x36AC8` places FP2.  The Makefile intentionally omits FP1/FP2 `--offset` values and lets `dsfwtool` recalculate this V1 order, rather than assuming stream lengths never change.  With no original V2 payload, this remains an explicit V1-baseline project choice, not historical V2 binary evidence.

## Version-dependent choices / 版本差异选择

| Area | V1 evidence | V3-and-later evidence | Selection for this inferred V2 |
| --- | --- | --- | --- |
| FP physical order | `P3 -> FP1 -> FP2` | `P3 -> FP2 -> FP1` in every known V3--V8a sample | **V1 order**; current starts are FP1 `0x29FA8`, FP2 `0x36AC8`, recalculated from effective stream ends. |
| FP1 retained-P1 edits | Keeps the `0x0F` counter gates at retail `+0x89E/+0x8BA`. | Adds the state-table/branch changes at `+0x2DC/+0x8CE` and changes both gates to `1`. | Take only `+0x2DC=0x0023` and `+0x8CE=NOP` for the reported direct-`.ds.gba` health-path change; retain V1's two `0x0F` gates. |
| FP2 prefix | Stores `DSBooterPASSFLSH` and has the V1 prefix instruction layout. | Stores `DSBooterPASS` and has a substantially rewritten prefix. | **V1 FP2 payload**, because no V2 evidence supports importing the V3 rewrite. |
| Primary H/P1/P2/P3/P4/P5 | — | The extracted V1 and V3 Phat plaintext components are byte-identical. | Shared byte baseline; there is no observed V1/V3 component choice here. |
| P3 verification policy | The extracted V1 P3 equals extracted V3 P3. | Same observed P3 bytes despite the historical high-level wording about V3. | Do not invent an extra V3-only P3/RSA patch; retain the shared V1/V3 P3 baseline. |
| H/FH tail fields and installer CRC | Source headers use the known template values; installer CRC overlays the final two FH bytes in a complete payload. | Same construction property. | Keep source H/FH patch fields unchanged.  Only the separate, non-source inferred image template is FF-filled and receives its terminal CRC16. |

| 项目 | V1 证据 | V3 及之后证据 | 本推断 V2 的选择 |
| --- | --- | --- | --- |
| FP 物理顺序 | `P3 -> FP1 -> FP2` | 所有已知 V3--V8a 样本均为 `P3 -> FP2 -> FP1` | **采用 V1 顺序**；当前 FP1 为 `0x29FA8`、FP2 为 `0x36AC8`，按有效流结尾重新计算。 |
| FP1 保留 P1 修改 | 保留零售 `+0x89E/+0x8BA` 的 `0x0F` 计数门。 | 增加 `+0x2DC/+0x8CE` 的状态表/分支修改，并将两处门值改为 `1`。 | 仅采用 `+0x2DC=0x0023` 与 `+0x8CE=NOP` 来模拟直接 `.ds.gba` 启动的健康屏路径变化；保留 V1 的两处 `0x0F`。 |
| FP2 前置区 | 保存 `DSBooterPASSFLSH`，并使用 V1 的前置指令布局。 | 保存 `DSBooterPASS`，且前置区有较大重写。 | **采用 V1 FP2 载荷**；没有 V2 证据支持导入 V3 重写。 |
| 一级 H/P1/P2/P3/P4/P5 | — | 提取出的 V1、V3 Phat 明文组件逐字节相同。 | 使用共享字节基线，此处不存在已观察到的 V1/V3 选择。 |
| P3 验证策略 | 提取出的 V1 P3 与 V3 P3 相同。 | 尽管历史文字对 V3 有高层描述，观察到的 P3 字节仍相同。 | 不凭空增加 V3 专有 P3/RSA 补丁；保留 V1/V3 共用 P3 基线。 |
| H/FH 尾字段及安装器 CRC | 源头部采用已知模板值；完整载荷的安装器 CRC 会覆盖 FH 的最后两个字节。 | 同样具有此构造属性。 | 源码 H/FH 补丁字段保持不变；只有工程外的推断完整镜像使用 FF 填充并补终端 CRC16。 |

## 历史变更记录依据

headspin 在 2005-05-24 的论坛帖中将 V2 描述为：保留 V1 功能、直接启动 `.ds.gba` 时移除健康屏幕、之后更新不再需要短接 SL1；同帖将背光渐亮、完全移除健康屏幕和取消 WMB RSA 签名检查列为 V3 项。紧随其后的 FourScience 回帖还称，其 V1 升级到 V2 时已显示不再需要短接 SL1。原帖作者以 “from my understanding” 表述，FourScience 则称其缓存过网页与文件，因此它们是同期的强旁证而不是找回的 V2 发布原件。

English source note: Headspin's 24 May 2005 post says V2 was V1 plus health-screen removal for direct `.ds.gba` boot and no further SL1 shorting; it lists fade-in, no health screen, and WMB RSA-check removal under V3.  FourScience then reports that a V1-to-V2 update already said no more SL1 short was needed.  Both are contemporaneous evidence, but Headspin explicitly says “from my understanding” and FourScience relies on cached material, so neither substitutes for a recovered V2 payload.

- [Wayback snapshot of post 43567](https://web.archive.org/web/20150811075617/https://forum.gbadev.org/viewtopic.php?p=43567)
- [Static gbadev forum archive, thread 5419](https://gbadev.net/forum-archive/thread/19/5419.html)

因此源码表达的是组件级结构与可追踪的推断修改，而不是会把整体搬移误识别为改动的镜像逐字节差分。
