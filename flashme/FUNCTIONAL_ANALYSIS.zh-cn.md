# FlashMe V1–V8a 功能分析

[English](FUNCTIONAL_ANALYSIS.md)

## 范围、证据与术语

本文是针对本目录中已重建 FlashMe 发布模板的一份全新、以代码为先的分析。它**不会**
复用早期的发布说明解读或推测性注释。证据仅限于 V1、V3、V4、V5、V6、V7 Old、V7 New、
V8、V8a 的提取/重建汇编，以及 [`../official/`](../official/) 下按运行地址组织的
任天堂 `official_v3`、`official_v6` 清单。
本地 `dsfwtool` 文档只用于交叉核对存储组件层与头部归属；随附的 BIOS7/BIOS9 清单
则用于确定具体 SVC 和私有 BIOS 调用的实际行为。本地 FlashMe 安装器 ARM7 源码仅用于其
明确的 `H+0x17C` / `FH+0x17C` 版本识别逻辑；本地 HBFirmware 构建器则仅在其源码注释与
赋值能直接识别 `H+0x17C`、`H+0x17E` 约定时使用。两者均不会被当作未展示的 FlashMe
发布行为的证据。

V2 被刻意排除：仓库中没有原始 V2 镜像或能够建立源代码级依据的参考物，因而不能判断
它的实际行为。

本文使用以下证据标记：

- **[D] 直接证据**：重建代码中的指令序列、常量、字符串字面量或控制流边直接证明。
- **[T] 控制流追踪**：沿任天堂 V3/V6 清单或 FlashMe 前置代码中紧邻的调用者/被调用者
  路径得出的结论。
- **[I] 保守解释**：对直接行为的严格收窄的功能性表述；不会断言尚未从代码恢复出的
  作者意图或用户界面效果。
- **[U] 未确定**：字节和局部作用已经明确，但更高层目的尚无法确认。
- **[H] 历史研究**：由项目整理的同期测试或发布背景；它记录历史触发因素，并与代码直接
  证据分开标示。
- **[E] 实机测试**：项目在真实硬件上观察到的可见行为；它确定版本级结果，但不替代对每条
  指令的控制流归因。

下文的“任天堂 V3”“任天堂 V6”始终指本工程使用的两份任天堂固件基底，不是
FlashMe V3 或 FlashMe V6。Phat 的 FlashMe 模板保留任天堂 V3 的 P1/P2/P3 材料；从
V7 开始的 Lite 模板则保留任天堂 V6 材料。所有已分析 FlashMe 构建中的 P4、P5 都是
未修改的 `incbin` 组件。

## 每个重建镜像中可见的组件模型

每个镜像都有两层启动组件：

| 组件 | 代码中可直接看到的构造方式 | 功能性理解 |
| --- | --- | --- |
| `H` | 从输入头派生，写入 FlashMe P1/P2 元数据；私有/校准范围按独立规则处理。 | **[D]** 新 P1/P2 对的主启动元数据。 |
| `P1`、`P2` | 新写入的紧凑 ARM9 与 ARM7 主程序。 | **[D]** 它们先于保留任天堂载荷执行，并选择/准备交接路径。 |
| `FH` | 指向 FP1/FP2 的第二份头。 | **[D]** 用于装载保留载荷层的元数据。 |
| `FP1`、`FP2` | FlashMe 写入的前置程序，后接完整的原任天堂 P1/P2。 | **[D]** 前置程序先运行，再跳入保留任天堂组件。 |
| 保留 P3 | Phat 使用任天堂 V3，V7 起 Lite 使用任天堂 V6；仅有三个小补丁位点。 | **[D]** 除列出的验证/状态变化外保留原组件。 |
| P4、P5 | 直接 `incbin` 输入组件。 | **[D]** 两者都没有 FlashMe 代码补丁。 |

FP1/FP2 前置程序在 RAM 中被放置于保留组件的紧前方：
`FlashMeFp{1,2}RamAddress = RetailP{1,2}RamAddress - prefixBytes`。随后，保留组件
仍在原本的运行时地址发出。因此，前置代码可以直接跳入原 P1/P2 例程，而无需重新定位
其内部的绝对地址引用。

V6 及以前的前置区为 `0x200` 字节，V7 起为 `0x400` 字节。这是可直接观察到的布局
变化；本文不假定其更高层设计动机。

### P3 运行期坐标修正

重建的 P3 补丁源码现使用从任天堂 P1 恢复出的 P3 执行基址：基于任天堂 V3 的 Phat
版本线为 `0x02358D00`，基于任天堂 V6 的 Lite 版本线为 `0x02358E00`。**[D/T]** 各自
P1 的 P3/P4 解码与 CRC 路径会将这一第一个地址精确作为 P3 输出范围；而已解码 P3
入口的第一条跨组件 `BL` 也只有在此基址下才会正确解析到 P1。故此前便于表达偏移的
`0x02380000` 不再被当作 P3 RAM 地址。由于 `headersize` 与后续每个 P3 `org` 共用
同一基址符号，修正坐标不会改变生成组件中的原始字节偏移。

本文刻意分开“镜像存储格式”与“运行时所在位置”。本地
[dsfwtool 组件资料](../../dsfwtool/README_ZH.md)记录主 P1/P2 的镜像层为加密
P12/LZ10 流，而 P3/P4/P5 使用 P345 双流静态 Huffman 数据。因此，下文即使在运行时
P1 内看到 P345 解码器，也只是它在解码其它固件载荷，不能反过来证明镜像中存储的 P1
本身使用 Huffman 编码。

### 两层 P12 的运行时证据

主 P1/P2 已加密而 FP1/FP2 未加密的区别，不仅来自工具文档，也能直接在随附 BIOS7 的
执行代码中看到：

- BIOS7 的启动路径会调用 `FUN_00002462`。该例程初始化 KEY1 状态，从已装载的主头读取
  P1/P2 描述符，并以描述符 `UNK_000033E0` 进入 `SVC_LZ77UnCompVRAM`。该描述符的逐字节
  读取例程为 `FUN_00002330`：每次补充八字节时，它会传输串行数据并调用 `Decrypt_64bit`，
  然后才把压缩字节交给 LZ77。
- 每个已恢复的 FlashMe 主 P2 则为次级 FH 中的 FP1/FP2 流提供自己的三字描述符。其
  `p2_legacy_wait` 直接从 `REG_SPIDATA` 读取一个字节，写回该字节以给下一个字节提供时钟，
  再把该字节返回给 `SVC_LZ77UnCompVRAM`；FlashMe 回调路径没有调用 `Decrypt_64bit`。

**[D/T]** 因此执行路径本身支持 dsfwtool 的分层模型：任天堂 BIOS 消费加密的主 P12 数据，
而 FlashMe 主 P2 消费未加密的次级 FP1/FP2 P12 数据。两层共用 LZ10 解码 ABI，正好解释了
为何它们可以使用相同的解压例程，却不共用加密步骤。

### 已核验的启动装载边界

下图表达的是组件装载关系，并不声称其中所有 ARM9 与 ARM7 指令按单一串行顺序执行：

```text
BIOS7 启动控制器（FUN_0000124A）
  └─ FUN_00002462：KEY1 + 加密 P12 读字节器 + LZ10
       ├─ 按 H 描述符推导的 ARM9 目标位置装载主 P1
       └─ 按 H 描述符推导的 ARM7 目标位置装载主 P2

FlashMe 主 P2
  └─ 读取次级 FH + 直接 SPI 读字节器 + 相同的 LZ10 ABI
       ├─ FP1 = FlashMe 前置区 + 保留的任天堂 P1
       └─ FP2 = FlashMe 前置区 + 保留的任天堂 P2

保留的任天堂 P2
  └─ 将 H 描述的 P3/P4 流一起、P5 流单独暂存到 RAM
       └─ 保留的任天堂 P1 P345 解码器重建 P3、P4、再到 P5，
          并应用对应的 P3/P4 合并 CRC16 与 P5 CRC16 闸门
```

**[D/T]** BIOS7 控制器中可见三条分支会调用 `FUN_00002462`，且该装载器使用主头描述符；
FlashMe P2 源码则读取 FH 描述符字段，并经由自身回调表到达 FP1/FP2。这区分了两个表面上
相似的问题：BIOS 决定主 P12 流如何解密与解压，而 FlashMe 决定已经是明文层的 FP 流如何
读取与解压。随后由保留 P1 调用的 P345 解码器属于另一阶段的 P3/P4/P5 载荷装载。保留
P2 的暂存代码已确定前两者是共享 CRC16 的 `part3`/`part4` 对，P5 则是独立字段。镜像
布局与头字段归属由本地 [dsfwtool 组件资料](../../dsfwtool/README_ZH.md)和
[`firmware_header` 字段定义](../../dsfwtool/include/firmware.h)交叉核验；执行调用边则来自
随附的 [BIOS7 清单](../../ndsbios/bios7.s)。

## 硬件与 ABI 命名锚点

下列名称均由 GBATEK 与 libnds 共同锚定，并非从 FlashMe 自定义标签猜测而来。这些
资料只用于给硬件/ABI 命名，不构成 FlashMe 作者意图的证据。

| FlashMe 使用项目 | 代码中可见的行为 | 已核验定义 |
| --- | --- | --- |
| `REG_KEYINPUT` / `REG_KEYXY` | 所有按键测试都会在被测位为清零时分支。 | libnds 提供按键掩码，且其按键扫描器会对寄存器读值取反，证实此处为低有效约定。[input.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/input.h)、[keys.c](https://raw.githubusercontent.com/devkitPro/libnds/master/source/arm9/keys.c) |
| `REG_IPC_SYNC` | FP1/FP2 通过高字节写入与低半字节观察的模式交换小阶段值。 | [GBATEK — NDS IPC](https://doc.kodewerx.org/documents/gbatek.html)、[libnds ipc.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/ipc.h) |
| `REG_BLDALPHA_SUB` (`0x04001052`) | 任天堂 P1 转场 A 向其写入打包的 5-bit Alpha 系数。 | [libnds arm9/video.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/arm9/video.h) |
| `REG_MASTER_BRIGHT` / `_SUB` | 任天堂 P3 状态闸门会把这两个地址传给 P1 写入例程。 | [libnds arm9/video.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/arm9/video.h) |
| ARM9 `REG_POWERCNT = 0x820F` | FP1 的 warm 路径与准备代码会在后续交接/阶段工作前写入此半字。 | `0x820F` 置位 POWCNT1 中 LCD、2D 引擎 A、3D 渲染器、3D 几何引擎、2D 引擎 B 及 LCD 交换对应的位。它是确定的显示供电/控制值，而不是加密或头状态值。[GBATEK — NDS 电源控制](https://doc.kodewerx.org/documents/gbatek.html)、[libnds system.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/system.h) |
| `REG_SPICNT` / `REG_SPIDATA` | FP2 与后期 P2 写入 `0x8A00, 0x84`，随后写入 `0x8200, 0x00`。 | `SPICNT` 的设备选择值 `2` 是触摸屏控制器；控制字节 `0x84` 会启动通道 0 的 12-bit、单端转换。[GBATEK — NDS SPI 与触摸屏控制器](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md) |
| 辅助 SPI / 卡带寄存器 | V7 FP2 与 V8a P2 轮询卡带控制、读取头，并使用 NDS 头中的 ARM9/ARM7 装载字段。 | [libnds card.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/card.h)、[memory.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/memory.h)、[GBATEK — NDS cartridges](https://doc.kodewerx.org/documents/gbatek.html) |
| 已装载的 NDS 头 Logo | 任天堂 P3 在一个被修改的状态转移前比较 `0x027FFEC0` 与 `0xFFFF0020`。 | GBATEK 将 156 字节 NDS Nintendo Logo 字段置于头部 `+0xC0`，头部会装载至 `0x027FFE00`；随附 BIOS9 清单在 `0xFFFF0020` 保存参考 Logo。[GBATEK — DS Cartridge Header](https://doc.kodewerx.org/documents/gbatek.html)，[BIOS9 清单](../../ndsbios/bios9.s) |
| `0x027FFE24`、`+0x28`、`+0x34` | FlashMe 交接代码会通过规范地址与零售机镜像地址读写这些 word。 | 它们是标准的已装载 NDS 头字段：ARM9 入口地址、ARM9 RAM 地址、ARM7 入口地址。`0x023FFE24/+0x28` 是前两个字段的零售机 4 MiB 主 RAM 镜像，不是 FlashMe 私有存储。[GBATEK — NDS BIOS RAM 与卡带头](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md) |
| `0x027FFF70` | V6 及以后的 FP1 会在此写入小型 ARM 返回跳板。 | 这正好是有文档记载的 `0x170` 字节已装载卡带头范围之后的第一个地址。GBATEK 将之后的范围记为卡带启动时清零的未使用区，并未赋予它跳板 ABI。地址边界是标准的，但将其用作跳板是 FlashMe 的本地选择。[GBATEK — NDS BIOS RAM](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md) |
| `0x02100024` | V7 及以后的 FP1 在回退返回路径中解引用此 word。 | 它位于普通主 RAM，GBATEK 与 libnds 都没有为它定义专用字段。对全部已解压的任天堂 V3/V6 P1–P5 组件进行 Ghidra 精确常量扫描后，没有发现静态字面引用；这不能排除经计算或外部代码写入，但可见 FP1 读操作不能证明它具有系统定义用途。 |
| ARM9 `SVC #0x0C` | V6 及以后 FP1 以 `r0 = 0xFFFF0020`、`r1 = 0x027FFEC0`、`r2 = 0x28` 调用。 | 随附 [BIOS9 清单](../../ndsbios/bios9.s)将其映射为 `SVC_CpuFastSet`；复制 `0x28` 个 32-bit word，即 `0xA0` 字节。 |
| `SVC #0x0E` | 任天堂 P1 包装器恰好是 `svc #0x0e; bx lr`。 | [libnds bios.h](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/bios.h)、[GBATEK — GetCRC16](https://doc.kodewerx.org/documents/gbatek.html) |
| ARM9 `SVC #0x1F` | FlashMe 主程序/FP1 以 `r0 = 1` 调用。 | 随附 [BIOS9 清单](../../ndsbios/bios9.s)的 SVC 表将 `0x1F` 指向 `SVC_CustomPost`；该例程把 `r0` 写到 `0x04000300`（`REG_POSTFLG`）。 |
| ARM7 `SVC #0x03` | FP2 的常规计时帮助例程以及 V8 Lite 的 `r0 = 0x280000` 延迟使用它。 | 随附 [BIOS7 清单](../../ndsbios/bios7.s)中它是 `SVC_WaitByLoop`：对 `r0` 递减并循环。 |
| ARM7 `SVC #0x08` | 每个 FP2 入口均使能电源、保留非零 `r0`、设 `r1 = 0x3000` 后调用它。 | 随附 BIOS7 清单中它是 `SVC_SoundBias`：当 `r0` 非零时使 `REG_SOUNDBIAS` 逐步增至 `0x200`，每步等待 `r1` 次循环。 |
| BIOS7 ARM `0x000030E4` | 主 P2 在布置次级层或替代路线后，会通过 `PrimaryP2ComputeRoutine` 槽进入此地址。 | 它是 BIOS7 `SVC_CpuFastSet` 的 ARM 入口（Thumb veneer 为 `0x000030E0`）；直接实现根据控制字以八个 word 为一组复制或填充。[BIOS7 清单](../../ndsbios/bios7.s) |
| 私有 BIOS7 `0x0000119D` | 多条 FP2 及 V8a P2 路径调用此地址；重建源码历史上称它为 `BiosBootReturnRoutine`。 | 它是随附 BIOS7 清单中 `SignalBootFinish` 的 Thumb 入口，向 `REG_POSTFLG` 写入字节 `1`。 |
| 私有 BIOS7 `0x00002369` | 重建源码历史上称它为 `BiosIpcSendRoutine`；FlashMe 传入 `r0/r1/r2` 后跳转。 | 它是通用 SPI 单字节帮助例程，并非 IPC。在普通 FlashMe 保留固件路径与主 P2 调用中，`r0 = 0`、`r2` 先为 `1` 后为 `0` 会选择电源管理设备并先保持、后释放片选；`r1 = 0` 选择控制寄存器 0，`r1 = 1` / `0x0D` 写入相应值。因此 `0x01` 打开声音放大器，`0x0D` 则同时打开声音放大器和两块背光。[GBATEK — SPI 与电源管理](https://doc.kodewerx.org/documents/gbatek.html) |
| 私有 BIOS7 `0x00002437` | 重建源码历史上称它为 `BiosCopyRoutine`；FlashMe 传入地址、目标 RAM 与字节数。 | 它是固件串行 Flash 读取帮助例程，而非 CPU 复制循环：发出 `0x03`（`READ`）命令、串行化地址、读取请求字节至 RAM 后释放片选。FlashMe 的设置路径传入 `0x3FE00`、`0x023FFC80`、`0x180`，正好对应两份固件用户设置区和当前设置 RAM。[GBATEK — 固件 Flash 与设置映射](https://doc.kodewerx.org/documents/gbatek.html) |
| 私有 BIOS7 `0x00002A2B` | V8a 主 P2 会以 `r3` 指向 `p2_legacy_pool` 后跳转至此。 | 它是 `SVC_LZ77UnCompVRAM` 的 Thumb 入口。其源码会调用描述符 `+0` 的源初始化回调、以描述符 `+8` 逐字节读取压缩流，并在结束时调用描述符 `+4`。 |
| 私有 BIOS7 `0x00002389`、`0x000033A5`、`0x000022C7` | 它们分别是 V8a `p2_legacy_pool` 中的三个支持地址。 | `0x2389` 发送串行 Flash `0x03` 及四字节地址；`0x33A5` 经调用者缓冲区执行按长度计数的主 SPI 全双工传输；`0x22C7` 发出结束用的零字节传输并返回零。这些描述来自随附 BIOS7 的实际指令，而不是 FlashMe 源中遗留的旧标签。 |

## FlashMe 修改的任天堂代码范围

源标签、运行时地址与字节级证据均维护在
[`../official/SEMANTIC_MAP.zh-cn.md`](../official/SEMANTIC_MAP.zh-cn.md)。以下是本文依赖的
功能性摘要。

### 保留 P1：P3/P4 与 P5 CRC16 闸门

| 任天堂基底 | 原始范围 | FlashMe 改动 | 已确认结果 |
| --- | --- | --- | --- |
| V3 | P1 `+0x6DE6`，`NintendoOfficialV3P1_P3P4Crc16Gate` 内 | 将 P3/P4 合并 CRC16 失配的 `bne` 换为 Thumb NOP。 | **[D]** 最后一次比较不再选择另一个 `0x408` 下游参数，而会走 `0x400` 路径。 |
| V3 | P1 `+0x6E3C`，`NintendoOfficialV3P1_P5Crc16Gate` 内 | 将独立 P5 CRC16 失配的 `bne` 换为 Thumb NOP。 | **[D]** 成功调用不再取决于这次最终 CRC16 比较。 |
| V6 | P1 `+0x6DAE`、`+0x6E04` | V6 对应的 P3/P4 与 P5 CRC16 闸门 Thumb NOP。 | **[D]** 同样绕过两个 CRC16 闸门。 |

P2 暂存路径已经确定双流为 P3/P4、单流为 P5：它读取 `part3_romaddr`、
`part4_romaddr`、`part34_crc16`，再单独读取 `part5_romaddr`、`part5_crc16`；这与
[`FW_HEADER`](../../dsfwtool/include/firmware.h)一致。前置的本地解码器与 `SVC #0x0E`
调用仍然存在。因此能直接得出的结论仅是：这些解码后的 P3/P4 与 P5 CRC16 分支闸门被
绕过；单靠这一补丁不能作为 RSA 或签名验证绕过的证据。

### 保留 P3：状态、密码验证与摘要闸门

| 任天堂基底 | 原始范围 | FlashMe 改动 | 已确认结果 |
| --- | --- | --- | --- |
| V3 | P3 `+0x1019C`，`NintendoOfficialV3P3_NdsHeaderLogoState0cTo0dGate` 内 | `beq` 改为 Thumb NOP。 | **[D/T]** P3 的父分派器会在状态 `0x0C` 调用此处理器。其 P1 辅助例程会将已装载的 156 字节 NDS 头 Nintendo Logo 字段（`0x027FFE00 + 0xC0`）与 ARM9 BIOS 的 `0xFFFF0020` 参考 Logo 比较。Logo 不匹配不再能跳过该状态处理器中的 `0x0D` 写入；此前的上下文检查和双主亮度渐变仍保留。 |
| V6 | P3 `+0x10198` | V6 对应 Thumb NOP。 | **[D/T]** V6 的父分派器同样会在状态 `0x0C` 调用对应处理器；同样移除了 NDS 头 Logo 闸门。 |
| V3 | P3 `+0x13ED0` | 将整个公钥格式化摘要入口替换为 `mov r0,#1; bx lr`。 | **[D/T]** 原函数把两个 `0x80` 字节值和一个三字节、指数大小的值转换为大整数，执行公钥运算；随后要求恢复块具有 `0x01 || 0xFF... || 0x00 || DER DigestInfo` 形状，并提取一个 20 字节 OCTET STRING。该结构即 RSASSA-PKCS1-v1_5 规定的结构。[RFC 8017，第 8.2、9.2 节](https://www.rfc-editor.org/rfc/rfc8017.html#section-8.2) 现在所有调用者都会在不执行主体的情况下得到成功。 |
| V6 | P3 `+0x13EEC` | 同一两指令桩。 | **[D/T]** 同样跳过大整数、PKCS#1 形状恢复消息、DER DigestInfo 与 20 字节提取路径。 |
| V3 | P3 `+0x173C0` | 将整个摘要比较入口替换为 `mov r0,#1; bx lr`。 | **[D]** 原本在返回 0 时清除状态标志的调用者现在会保持成功条件。 |
| V6 | P3 `+0x173DC` | 同一两指令桩。 | **[D]** 结果相同。 |

现已可从代码直接恢复 V3 与 V6 中该补丁周围的 P3 状态序列。父分派器先在状态
`0x0B` 使用一个处理器：计数至 `0x1E`，把同一个插值结果写给两个主亮度写入器，随后
清零计数器并切换至状态 `0x0C`。状态 `0x0C` 的辅助例程继续计数至 `0x5A`：在
`1..0x0F` 写入 `0x10 - 插值`，在 `0x10..0x4B` 写入零，在 `0x4C..0x5A` 写入该插值；
两套写入都同时作用于两个主亮度写入器。只有该定时辅助例程成功后，才会进行上下文检查
和 Nintendo Logo 比较；成功时切换至状态 `0x0D`，其处理器执行后续清理与续接工作。
FlashMe 的 NOP 只改变比较后的最终条件分支，不会移除状态 `0x0B` 或 `0x0C` 的亮度阶段。
这已能确定局部状态机行为，但单凭该范围仍不能命名它对应的用户可见画面。

清单中的函数名仍是分析用名称，但第一个位点的行为已可直接恢复，而不是只根据数据大小
推断：其恢复消息解析器遵循 RSASSA-PKCS1-v1_5 规定的
`0x01 || 0xFF... || 0x00 || DER DigestInfo` 形态。后一个 V3/V6 位点则独立构建 SHA-1
形态的 20 字节摘要（含标准 SHA-1 初始字），并调用明确的 20 字节相等比较例程。与 P1
CRC 改动不同，这两处完整的成功桩是公钥格式化摘要路径和独立摘要相等结果被覆盖的直接证据。

NDS 头 Logo 状态补丁必须与这些验证桩分开看待。它改变的是已确认状态 `0x0C` 处理器中、对
`REG_MASTER_BRIGHT` 与 `REG_MASTER_BRIGHT_SUB` 进行定时写入之后的一次最终状态转移；
它能证明这个特定 Logo 比较闸门被绕过，但本身不能证明更大状态机对应哪个用户可见画面或警告画面策略。

### 保留 P1：仅普通构建启用的 Alpha 转场修改

FlashMe V3 的唯一构建，以及 V4 起的 normal（相对的 stealth 为保留健康提示变体）构建，会如下修改任天堂
P1。Phat 使用 V3 偏移，Lite 使用 V6 对应偏移。

| 位点 | 字节级变化 | 直接结果 |
| --- | --- | --- |
| P1 主循环分派器的首个表项 | `0x0017` → `0x0023` | **[D/T]** P1 的复位/主循环会在初始设置后调用此分派器。其外层选择器为零时，该首个表项将副屏 Alpha 转场 B 重定向到 A。 |
| 转场 A 比较 1 | `cmp #0x0F` → `cmp #1` | **[D]** 降低原转场循环使用的一个阈值。 |
| 转场 A 比较 2 | `cmp #0x0F` → `cmp #1` | **[D]** 降低同一序列中的第二个阈值。 |
| 转场 A 终结分支 | 条件跳转 → Thumb NOP | **[D]** 阻止原本在此处的终结返回，使控制流落入后续连续代码。 |

目标例程写入的是副引擎 Alpha 混合系数寄存器 `REG_BLDALPHA_SUB`，不是主亮度或背光
寄存器。因此 **[D]** normal 构建缩短并重定向了一个副屏 Alpha 转场，stealth（保留健康提示）
构建不发出上述四项修改，保留任天堂 V3/V6 在这些位置的原字节。两份独立的历史说明均明确
记载 normal 会移除 Nintendo Logo 与健康/安全提示，而 `FlashMe_Stealth` 保留它们
（[GameBrew](https://www.gamebrew.org/wiki/FlashMe)、[HomeBrewGr](https://lnxt.gr/en/tutorials/post/howto-flashme-passmesuperpass/)）。
故版本级的显示策略为 **[D/H]**：stealth 显示健康提示，normal 不显示；但单靠这四项 P1
字节修改，仍不能把其中某一条指令单独归因于画面的某一像素阶段。

**[E]** 本项目实机对照进一步将两项显示行为拆开：V1 normal 会先出现非官方黑→白渐变，
随后显示健康提示；V3 normal 仍有该渐变、但不再显示健康提示；V4 normal 与 V3 normal
相同；V4 stealth 跳过渐变，接近原固件的白屏后显示健康提示。因此“normal 不显示健康提示”
绝不等同于“normal 不执行背光渐变”。

## 主 P1/P2：第一阶段交接与替代启动路径

### V1–V4 主组件对

V1/V3 的主 P1 是很小的 ARM 跳板：它会经由 `r12` 存储传入的续接字，读取本地交接槽，
然后跳转。V4 源码保留这一主 P1 形状。主 P2 会切换到 Thumb，使用其常量池中保留的
既有固件回调地址，然后选择以下两条路径之一。

| 测试 / 路径 | 直接行为 | 收窄的功能结论 |
| --- | --- | --- |
| `REG_KEYINPUT` 低半字节为零 | **[D]** V1–V4 使用 `lsl r1,#28; beq p2_copy_boot`；按键为低有效，因此表示 A+B+Select+Start 全部按住。 | 选择 `p2_copy_boot` 交接。 |
| `0x080000AC` 的 GBA Game Code 等于 `BOOT` | **[D]** 在按键判断之后，仍会选择同一 `p2_copy_boot` 路径。 | 使用 `BOOT` Game Code 的 Slot-2 卡带不需四键条件也能选择此交接。 |
| 两项均不成立 | **[D]** 读取次级 FH，根据其中两组描述符推导 FP1/FP2 的源与 RAM 目标，再两次调用 BIOS7 LZ77 回调装载器。 | 重建保留 FP1/FP2 层并继续通常的固件侧交接。 |

该路径会将三个字的 ARM9 交接跳板复制到 `0x023FFE24`：第一个字是目标槽，初值为
`0x023FFE28`；其后在 `0x023FFE28` 放置 ARM 指令
`ldr r0,[pc,#-0xC]; bx r0`。因此它起初会跳回自身，直到另一个执行参与方改写这个目标
字。主 P2 把代码入口 `0x023FFE28` 写入主 P1 交接槽，并让最终 ARM7 `SVC_CpuFastSet`
尾部的 `LR` 为 `0x080000C0`。**[D/T]** 这明确证明了 ARM9 等待/交接跳板，以及 ARM7
从 Slot-2 程序常规入口偏移继续执行；它是一条替代的双 CPU Slot-2 启动路径。释放 ARM9
跳板的后续写入者不在这个紧凑主组件对中，所以不为它附加未经证实的恢复策略含义。V5–V8
保留相同的复制跳板结构。

### V5–V8 主组件对

V5 将主 P1 从“存储再跳转”的跳板改为直接经本地续接槽跳转。其主 P2 会向对应的新槽
偏移写入续接地址；V6、V7、V8 都保留了该安排。源码同时将**主 P2 读取的次级 FH 位置**
（历史符号虽名为 `FlashMePrimaryHeaderAddress`，但该名称易造成误解）从 `0x3FC80` 移到
`0x3F680`，并改变头类型编号配置。这些都是 **[D]** 的布局和交接变化；主 H 的 `1`→`2`
分类以及 V5 以后 FH 子版本字节的安装器侧含义见下文。

**[H]** 这次下移避开了末尾 `0x600` 字节主机专属尾区中前 `0x400` 字节的 Wi-Fi 接入点设置。
历史研究记录显示，Mario Kart DS 的线下试玩/联机测试暴露了旧 `0x3FC80` 布局会覆盖这些设置，
因此 V5 采用 `0x3F680`。尾区归属和 `0x600` 地址差可由构建布局直接核对；测试发现这一历史
触发因素不属于仅从汇编控制流可得出的结论。

V5–V8 P2 的 `BOOT` 与 A+B+Select+Start 选择逻辑，保持与 V1–V4 相同的直接模式。V7
没有改变这两个主 P2 测试；它的较大功能改变发生在 FP1/FP2。

### V8a 主组件对

V8a 替换了两份紧凑的主程序。新主 P1 是一个命令循环：命令 `1` 会清除 DMA 控制字，
以 `r0 = 1` 调用 ARM9 `SVC #0x1F`（故 `SVC_CustomPost` 会向 `REG_POSTFLG` 写入 `1`），
关电源，配置/清除 VRAM，设置 WRAM 所属，清除 OAM 与调色板 RAM，清除主、副 `DISPCNT`，
最后清除命令字。

V8a 主 P2 在 **Start+Select** 均按住（低有效）或 Slot-2 Game Code 为 `BOOT` 时选择其
替代路径。之后它会：

1. 向主 P1 写入命令 `1`，并等待 P1 循环将其清零；
2. 通过私有 BIOS7 `0x00002437` 把固件地址 `0x3FE00` 开始的 `0x180` 字节读入
   `0x023FFC80`；这包括设置区 1 和设置区 2 的前 `0x80` 字节。它比较二者更新计数器
   （`+0x70` / `+0x170`），当设置区 2 更新时，将其 `0x80` 字节活动设置记录复制覆盖
   RAM 中的设置区 1；
3. 执行下文所述的 `SPICNT/SPIDATA` 事务、清除 DMA、使能电源，然后以 `0x3000` 步间
   延迟调用 ARM7 `SVC_SoundBias`；
4. 检查 BIOS7 维护的 `0x027FF80C` 半字：BIOS7 `FUN_0000121A` 会先将其标记为非零，
   只有当已装载的 Slot-1 头同时具有预期的 Nintendo Logo CRC16（`0xCF56`）及匹配的
   头 CRC16 时才清零。非零值选择旧 Slot-2 跳板，零值选择 Slot-1 数据装载路径。

Slot-1 路径读取的偏移为 `+0x20/+0x24/+0x28/+0x2C` 和
`+0x30/+0x34/+0x38/+0x3C`，正是 libnds `tNDSHeader` 的 ARM9/ARM7 ROM 偏移、入口、
RAM 地址和大小字段。它发出标准的加密 DS 卡带主数据命令 `B7aaaaaaaa000000h`，按
`0x200` 字节分块读取。ARM9 传输会刻意从 ROM `0x8000` 开始——这是该命令允许的最低
地址——并按头中的 ARM9 ROM 偏移调整目标和长度；因此 `0x8000` 前的 ARM9 切片留给先前的
启动状态。ARM7 传输则直接使用其头内 ROM 偏移。最后，P2 把 ARM9 入口地址写入主 P1 的
命令字；P1 对非 `1` 的命令会跳转至该地址，同时 P2 跳至 ARM7 入口。**[D/T]** 这是真正将
两个 CPU 交接至有效 Slot-1 NDS 程序的路径，而非仅探测头部。手动触发和无效头回退是可直接
确认的行为；无需把实现强行命名为“修复模式”。

### 所有主 P2 版本：流式次级 P12 解码路径

该主 P2 次级层装载器存在于每个已恢复的 V1、V3–V8a 模板中。V8a 在新的替代卡带路径旁仍保留
它：当 **Start+Select** 与 `BOOT` Game Code 均未选择替代路径时，`p2_service_boot` 会把固件
镜像本身作为 BIOS7 LZ77 解码器的流式来源：

1. 它调用 `0x00002437`，把 FlashMe 次级 **FH** 头位于 `0x3F680` 的开头读入头部工作区。V1 至
   V8 请求 `0x70` 字节；V8a 请求 `0x40` 字节，但仍覆盖此处使用的全部字段。
2. 对 **FP1** 取 `FH+0x0C/+0x0E`，再对 **FP2** 取 `FH+0x10/+0x12`，并结合 `FH+0x14` 的
   shift 字段。两次计算分别得到 Flash 中的源位置和位于 FP1/FP2 RAM 基址下方的运行时目标。字段归属与
   本地 [dsfwtool 组件资料](../../dsfwtool/README_ZH.md)一致。
3. 每个 FP 组件均以三字描述符进入 BIOS7 `SVC_LZ77UnCompVRAM`（`0x00002A2B`）。
   `p2_legacy_thunk` 在计算出的源地址开始串行 Flash `READ (0x03)` 并预置 SPI 传输；
   `p2_legacy_wait` 等待 `SPICNT` 空闲、返回收到的 `SPIDATA` 字节，再将该字节写回以给下一个
   字节提供时钟。描述符的结束回调为 BIOS7 `0x000022C7`。

P2 还明确给出了计算式。令 `s = FH+0x14`，则
`FP1_source = FH+0x0C << (2 + (s & 7))`，并且
`FP1_destination = 0x02800000 - (FH+0x0E << (2 + ((s >> 3) & 7)))`。
FP2 对应使用 `s >> 6` 与 `s >> 9` 两组 shift，目标基址为 `0x03810000`。这些是 P2 自身
的指令所得，而非仅按布局反推的公式。

**[D/T]** 这是一条提供给 BIOS LZ77 解码器的自定义串行流来源，而非普通的 RAM 到 RAM
解压调用。它正是 dsfwtool 所述未加密 **FP1/FP2** 的 P12/LZ10 模型的运行时对应物：每个已恢复
的主 P2 次级层路径都会先从固件 Flash 重建两份保留的次级组件，再交还给主 P1 路径。旧名称
`PrimaryP2Legacy*` 仅为历史源码标签，不能据此推断另有未知的压缩格式。

## FP1：ARM9 前置生命周期与硬件准备

FP1 会先于保留的任天堂 P1 执行。其分支由 `REG_IPC_SYNC` 低半字节控制；以下阶段名
只是对代码中观察到的字面值命名，不是恢复出的任天堂协议名称。

| 版本 | 代码中可见的变化 | 已确认行为 |
| --- | --- | --- |
| V1、V3 | `0x200` 字节前置区；等待阶段 `>= 0xB`；`0xB` 选 warm，较高阶段选 cold。 | **[D]** warm 路径向 ARM9 `REG_POWERCNT` 写入 `0x820F`（启用上表所列 LCD/显示引擎位）并等待阶段 `0xD`；cold 路径清 DMA 控制、经 ARM9 `SVC_CustomPost` 向 `REG_POSTFLG` 写入 `1`、清视频相关内存、设置 WRAM 控制、清 OAM/调色板，并在进入保留 P1 前安装/使用返回跳板。 |
| V4、V5 | 加入 `BuildStealth` 分支；从可见 cold 路径移除 `SVC_CustomPost`/`REG_POSTFLG` 写入。 | **[D]** stealth warm 启动直接跳入保留 P1；normal warm 启动仍写入电源状态并等待 `0xD`。 |
| V6 | 恢复 `SVC_CustomPost`/`REG_POSTFLG` 写入；改变 cold 路径跳板布置，并加入条件性头部区域清零/复制。 | **[D/T]** 配置基址为 `0x02800000`。当 BIOS7 的 Slot-1 头有效性镜像 `0x027FFFFC` 非零时，FP1 清零 `0x027FFE00..0x027FFF6F`，再以 `SVC #0x0C` 从 ARM9 BIOS `0xFFFF0020` 向 `0x027FFEC0` 复制 `0xA0` 字节。结果是一个清零的头前缀加上规范的 Logo/CRC 区；其前 `0x9C` 字节正是保留 P3 会比较的 Nintendo Logo 范围。触发条件现已确定为 Slot-1 头无效状态。FlashMe 已独立强制 P3 比较转场成功后，为何仍需要这个合成头，仍为 **[U]**。 |
| V7 Old、V7 New、V8 | 前置区增加至 `0x400`；阶段逻辑区分 `<0xB`、`0xB`、`0xC`、`>0xC`；normal warm 路径等待 `0xE`。 | **[D/T]** cold 准备先写入全禁用 VRAMCNT 模式，清除 LCDC 映射 VRAM，恢复 ARM7 WRAM 分配，执行同样的 `0xFFFF0020` → `0x027FFEC0` 条件复制，再通知阶段 `0xE`。 |
| V8a | 保留 V7/V8 的 FP1 形状，同时搭配 V8a 主阶段。 | **[D]** cold 准备额外向 `0x04000000`、`0x04001000`（`REG_DISPCNT`、`REG_DISPCNT_SUB`）写零。 |

`BuildStealth` 的影响不止于保留 P1 的 Alpha 编辑：它还移除了 normal warm 路径的阶段
等待、选择直接进入保留 P1，并跳过 normal FP2 的 PWM 背光渐亮。故代码可以证明其启动
时序/电源过程不同；结合上述 **[E]** 实机结果，可将该版本级结果确定为“无渐变、保留健康提示”。

## FP2：ARM7 选择、FlashMe 启动、保留固件路径与卡带装载器

### 通用选择测试

未启用 `BuildNoAuto` 时，V1 至 V8a 都存在默认 FP2 选择器：

| 被测条件 | 分支结果 | 证据 |
| --- | --- | --- |
| 按住 `<code>Select</code>` | 保留固件路径 | **[D]** `tst r0,#KEY_SELECT; beq fp2_service_boot`；输入为低有效。`fp2_service_boot` 是分析标签，不是已恢复的作者原始名称。 |
| 同时按住 `<code>A+B+X+Y</code>` | FlashMe 路径 | **[D]** A+B 在 `REG_KEYINPUT` 中测试，X+Y 在 `REG_KEYXY` 中测试；两个掩码结果都必须为零。 |
| Slot-2 Game Code 为 `PASS` | FlashMe 路径 | **[D]** GBA 头 `+0x0C` 的 32 位字与 `PASS` 字面量比较。 |
| Slot-2 Game Title 以 `DSBooter` 开头 | FlashMe 路径 | **[D]** GBA 头 `+0x00` 的前八个标题字节与 `DSBooter` 比较。 |
| 以上均不成立 | V1–V6、V8 走保留固件路径；V7 先探测 Slot-1 路径 | **[D]** 具体差异见下文。 |

`BOOT` 是主 P2 中的独立测试，且先于 `PASS`/`DSBooter` 选择器取得控制权。它进入上文
主组件的替代路径，不能与普通 FP2 FlashMe 选择测试混为一谈。

### 通用 FlashMe 与保留固件路径

FlashMe 路径调用私有 BIOS7 `0x00002437`，把固件地址 `0x3FE00` 开始的 `0x180` 字节读入
`0x023FFC80`。这跨越用户设置区 1 与设置区 2 的前 `0x80` 字节。`+0x70` 与 `+0x170` 的
半字是其更新计数器；若设置区 2 更新，则 BIOS CPUFastSet 会把其前 `0x80` 字节（`0x20`
个 word）覆盖到 RAM 中的设置区 1。接着代码清除 DMA 控制、交换预期 ARM7/ARM9 阶段值，
并跳至配置的 ARM7 返回地址。这是具体的用户设置选择与启动交接序列，而不是不透明的头传输。

每个 FP2 变体的入口都会写入电源控制值 `1`，让 `r0` 保持非零，设置 `r1 = 0x3000`，
再调用 ARM7 `SVC #0x08`。随附 BIOS7 的实现为 `SVC_SoundBias`，故它会把
`REG_SOUNDBIAS` 一步步提高到 `0x200`，每一步之间等待 `0x3000` 次循环。

标准 normal 保留固件路径写入阶段 `0xB`，以 `0x1800` 步长让计数器从 `0x1000` 前进至
`0x20000`，写入终结阶段后进入保留 P2。每轮先等待，再通过 BIOS7 `0x00002369` 对电源管理
寄存器 0 连续写入 `0x01`、`0x0D`。这两个值分别只打开声音放大器，以及打开声音放大器与
两块背光。在第一次写入 `0x0D` 后，每轮会让背光保持开启的 `r5` 等待时间不断增长，再让
背光关闭的 `0x20000 - r5` 等待时间不断缩短。GBATEK 记录这种开/关占空比方法可用于背光
PWM 调光，故 **[D/T]** normal 路径实现了背光渐亮。stealth 变体不执行该循环：写入初始
阶段写入后直接进入保留 P2，因此会跳过这段代码驱动的渐亮过程。

V4 首次在 FlashMe 路径中发出如下两次 ARM7 SPI 事务：

```
REG_SPICNT = 0x8A00; REG_SPIDATA = 0x84;
等待 SPI busy 清零；
REG_SPICNT = 0x8200; REG_SPIDATA = 0x00;
```

GBATEK 指明设备选择值 `2` 就是触摸屏控制器，所以 `0x8A00`/`0x8200` 不只是“看起来像
SPI”的数值：它们都会选择该设备，且首个传输会保持片选。首字节 `0x84` 包含 TSC 启动位，
请求通道 0（Temperature 0）的 12-bit、单端转换；第二个传输在释放片选的同时送出零字节。
**[D]** 代码完全没有读取返回数据，因此在这个可见范围内它执行了确切的控制器命令序列，
却没有取得可用的温度样本。**[U]** 仅凭代码仍无法确定 FlashMe 为什么要进行这次
转换/选中事务。V4 在它之前不再调用早期显式的私有 BIOS `SignalBootFinish`；V6 恢复该调用
并保留两次 SPI 事务。`SignalBootFinish` 会向 `REG_POSTFLG` 写入字节 `1`，因此这里的区别
是确切的标志写入差异，而非笼统的“boot return”。V7 及以后在其 cold boot 路径中保持这一
大致顺序。[GBATEK — NDS SPI 与触摸屏控制器](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md)

### V7 的 Slot-1 装载路径

当 V7 的 normal 选择器既未匹配 `PASS`/`DSBooter` 头，也没有强制选择 FlashMe 时，它
会进入 `fp2_aux_probe`，而不是立即进入保留固件路径。探测前它向 `REG_AUXSPICNT` 写入
`0xA040`。libnds 将该值定义为
`CARD_ENABLE | CARD_SPI_ENABLE | CARD_SPI_HOLD`：Slot-1 卡带接口与其辅助 SPI 总线
被启用，且辅助 SPI 的片选会跨越字节传输持续保持。由此可以确认探测所用总线，但不能据此
给另一端的外设强行命名。

直接可见的序列为：

1. 在辅助 SPI 上发送 `0xF2`，要求之后的响应依次为 `0x32`、`0x10`；
2. 发送 `0xF1`，然后经卡带/DMA 路径将 `0x200` 字节读到 `0x02100000`；
3. 以 `0xFFFF` 为种子，对 `header + 0xC0` 开始的 `0x9C` 字节执行 `SVC #0x0E`，并将
   结果与 `header + 0x15C` 比较；
4. 成功时 DMA 传输 ARM9 的 `+0x20/+0x28/+0x2C` 字段和 ARM7 的
   `+0x30/+0x38/+0x3C` 字段，随后跳至 `+0x34` 的 ARM7 入口；
5. 失败时通过辅助接口发送 `0xF0`，再进入保留固件路径。

传输使用卡带总线寄存器（`REG_CARD_COMMAND`、`REG_ROMCTRL`、`REG_CARD_DATA_RD`），
并将 `REG_ROMCTRL` 配置为 `0xA9000000`。按 libnds 的定义，该值是
`CARD_ACTIVATE | CARD_nRESET | CARD_CLK_SLOW | CARD_BLK_SIZE(1)`；块大小选择值 1
对应 `0x200` 字节。其卡带命令是 `A4 00 aa aa aa 00 00 00`，不是标准主数据 `B7` 命令；
libnds 的标准卡带命令常量表中没有 `A4`。上述偏移与 CRC16 范围恰好是 libnds 记录的
NDS 头 ARM9/ARM7 字段以及 Nintendo Logo CRC 字段。因此 **[D/T]** V7 含有一条设备专用的
卡带总线 NDS 头装载器：它先验证 Logo CRC16，再启动装载的 ARM9/ARM7 载荷，不能与
V8a 的标准 `B7` Slot-1 装载器混同。

该协议的精确名称应刻意保留为空。官方 libnds `card.h` 给出的标准辅助 SPI EEPROM 命令
包括 `0x01`、`0x02`、`0x03`、`0x05`、`0x06`、`0x9F`、`0xAB`、`0xB9` 等，却不包括
`0xF0`、`0xF1`、`0xF2`。因此后者只能证明存在非标准的辅助设备握手，不能单凭这些字节
就断言它是某一种特定 PassMe 或卡带实现；在可见握手之外的高层语义仍为 **[U]**。

V7 Old 的两个机型族均含此装载器。V7 New Lite 的该前置代码与 V7 Old Lite 完全相同。
V7 New Phat 则在 stealth cold 交接前增加 `BuildStealth` 专用 SPI 设置：发送 `0x84`，
检查响应 bit `0x40`，并有条件地从头 `+0x64` 的字节推导后续控制字；其 SPI 写帮助例程
还会等待响应。该机型专用设置的硬件目的仍为 **[U]**。

### V8 与 V8a 选择器变化

V8 的 FP2 仍保留 V7 辅助/卡带帮助程序字节，但顶层选择器不再跳入 `fp2_aux_probe`：
不匹配的 GBA 头会直接进入 `fp2_service_boot`。在重建的 FP2 前置程序内部，没有其他
入口会到达这些 V7 装载帮助程序。因此这些帮助程序字节在 V8 中仍存在，却无法从常规
FP2 入口路径到达。

V8 还加入 `BuildNoAuto`：

| 变体 / 版本 | FP2 入口处编译出的选择器 | 已确认的用户输入效果 |
| --- | --- | --- |
| V8 normal 或 stealth | 上述默认选择器 | `<code>A+B+X+Y</code>` 与 `PASS`/`DSBooter` 可选择 FlashMe；按住 `<code>Select</code>` 选择保留固件路径。 |
| V8 noauto 或 stealth-noauto | 只有 A+B+X+Y 测试能到达 `fp2_flash_boot`；保留的标题/代码测试没有入边 | **[D]** 必须按住全部四键才能选择 FlashMe；`PASS`/`DSBooter` 不再自动选择。 |
| V8a normal 或 stealth | 上述默认选择器 | 默认按键/标题/代码行为相同。 |
| V8a noauto 或 stealth-noauto | 按住 `<code>Select</code>` 到达 `fp2_flash_boot`；松开 Select 则进入保留固件路径 | **[D]** noauto 的手动触发从 A+B+X+Y 改为 Select。 |

V8 将固件用户设置读取/选择序列移入保留固件路径以及 cold FlashMe 路径。V8 Lite 用一次 ARM7
`SVC #0x03` 的 `SVC_WaitByLoop` 延迟（`r0 = 0x280000`）取代 normal 电源管理 SPI 写入
循环，然后写入终结阶段并交接给保留 P2；因此这条 normal V8 Lite FP2 路径不再执行此前的
PWM 背光渐亮。其设置读取例程还执行 Lite SPI 设置。V8a 保持对应的 Phat/Lite FP2 选择；
V8a 较大的新卡带启动行为位于主 P2，而非 V8a FP2 选择器。

## 头层变化

每份重建的 `patch_h.s` 与 `patch_fh.s` 都从提供的任天堂头开始，针对可重现模板将
`0x28..0x17B` 填为 `0xFF`，随后写入 P1/P2 RAM 地址字段。`H` 接收主 P1/P2 地址；
`FH` 接收 FP1/FP2 地址。若给出 shift 覆盖值，两份头都会写入该值。当前重建中两份头
均将 `+0x17E` 设为 `0xFFFF`。

| FlashMe 版本线 | `H + 0x17C` | `FH + 0x17C` | 安装器识别结果 | 主 P2 读取的次级 FH 位置 | 可直接观察到的变化 |
| --- | ---: | ---: | --- | ---: | --- |
| V1、V3、V4 | `1` | `1` | 旧式 FlashMe；不会解出单独的 V1–V4 号。 | `0x3FC80` | 初始重建布局族。 |
| V5 | `2` | `2` | V5（`2 + 3`） | `0x3F680` | 头位置变化，并开始安装器的 V5+ 子版本方案。 |
| V6 | `2` | `3` | V6（`3 + 3`） | `0x3F680` | 安装器 V5+ 子版本递增到 V6。 |
| V7 Old / V7 New | `2` | `4` | V7（`4 + 3`） | `0x3F680` | FP 前置区增长至 `0x400`；Phat/Lite 基底分离。 |
| V8 / V8a | `2` | `5` | V8（`5 + 3`）；该字段无法区分 V8a。 | `0x3F680` | V8 变体选择器、V8a 主阶段变化与这一标记对同时存在。 |

此表记录的是构建源码发出的字面数据。本地 FlashMe 安装器 ARM7 源码定义
`MAJOR_VER = 0x17C` 与 `MINOR_VER = BACKUPHEADER + 0x17C`，其识别分支是明确的：
`H+0x17C == 1` 报告旧式 FlashMe，`== 2` 时读取 `FH+0x17C + 3` 作为 V5 以后的
FlashMe 版本，`== 3` 报告 HB firmware，`== 0xFF` 则将镜像视为源任天堂固件。因此
`FH+0x17C` 序列不是运行期启动 ABI，而是仅在主 H 类型为 `2`、已选择 V5+ 分支后才使用的
安装器子版本字段。V8 与 V8a 模板都带 `5`，故该识别代码都会报告为 V8。随附的本地
安装器源码逐字给出了这条分支；公开保存副本也能独立看到相同代码。后者只用于交叉
核验该分支，不作为原始作者归属的证据。
[安装器 ARM7 源码公开保存副本](https://raw.githubusercontent.com/layeraudioai/flashme/master/arm7.c) · [独立固件格式记录](https://retroisle.com/others/nintendods/Technical/Firmware/dsfirmware.php)

安装器将 `oldFW` 声明为 `u8 *` 并按下标读取，因此这是 `+0x17C` 的**单字节**分类值。
重建源码之所以用 `.dh` 写入，仅仅是因为此头字段在别处按 halfword 处理：表中所有小端
输出都在 `+0x17C` 写入代码字节、在 `+0x17D` 写入零。它不能被误当作 16-bit 的版本号。

换言之，安装器的精确判定树如下：

| `H+0x17C` | 安装器分类 | 是否读取 `FH+0x17C` | 此安装器显示的结果 |
| ---: | --- | --- | --- |
| `1` | 旧式 FlashMe 家族（已还原的 V1/V3/V4 模板属于此类） | 否 | `FM-??`；不会区分 V1–V4。 |
| `2` | V5+ FlashMe | 是 | `FM-V(FH+0x17C+3)`。 |
| `3` | HB firmware | 否 | `HB`。 |
| `0xFF` | 源任天堂固件 | 否 | 另行推导出的源固件版本字符串。 |
| 其他 | 未识别 | 否 | `?`。 |

因此，只有在 `H+0x17C=2` 的分支内，`FH+0x17C=2/3/4/5` 才分别表示 V5/V6/V7/V8。
它不是通用的 FH 版本字段，单独不能识别 V1–V4、HB firmware 或 V8a。

这也与启动代码相符：已还原的主 P2 只读取 FH 的前 `0x70` 字节（V8a 为 `0x40`）来取得
FP1/FP2 描述符，没有任何路径会读到 `FH+0x17C`。该字段是安装器元数据，不属于主启动
加载器的运行期描述符 ABI。

随附 HBFirmware 构建器独立地将 `H+0x17C = 3`，并明确把相邻类别写为
`1 = old FlashMe`、`2 = FlashMe`（其中一个快照还将 `1` 说明为 pre-MK / Wi-Fi unsafe）。
重建出的主头值恰好符合这个约定：V1/V3/V4 使用 `1`，V5 及以后使用 `2`。
[HBFirmware 构建器](../../flashme-old/hbfirmware-090807/hbfirmware/installer/arm9/source/makebootstrap.c)

同一构建器把 `H+0x17E` 命名为识别源任天堂固件版本的已保留旧 CRC；若传入字段为
`0xFFFF`，它会在替换 P1/P2 前回退使用传入 `H+0x06` 的 P1/P2 CRC16。这确定了该字段的
构建期约定；重建模板则有意将它与已清理的私有头范围一起保持为 `0xFFFF`。

## 逐版本变化记录

这里是变化矩阵，不是发布说明时间线。每行描述相对前一个可获得版本线、实际重建源码
新增或移除的内容。

| 版本线 | 源码级变化 | 已确认的功能结果 |
| --- | --- | --- |
| V1 | 引入双层 P1/P2 与 FP1/FP2 构造；补丁 V3 P1 的 P3/P4 合并与 P5 CRC16 闸门，以及 V3 P3 的最终状态/验证/摘要入口。 | **[D/T/E]** 安装替代主/FP 交接，绕过两个已追踪的 CRC16 闸门，并让两个 P3 验证相关入口固定成功。其 normal FP2 路径含 PWM 黑→白渐变；实机确认渐变后仍显示健康提示。它**不**含后来四项保留 P1 Alpha 转场修改。 |
| V2 | 无原始模板或源代码。 | 排除；不对行为进行重建断言。 |
| V3 | 加入四项仅 normal 使用的保留 P1 Alpha 转场修改；仍使用 V1 风格主/FP 布置。 | **[D/E]** normal V3 改变第一个 Alpha 转场分派及阈值/终结行为；实机确认黑→白渐变保留、健康提示不显示。 |
| V4 | 在 FP1/FP2 加入 `BuildStealth` 替代分支，并保留仅 normal 的 P1 Alpha 编辑；省略 cold FlashMe 路径中显式的 `SignalBootFinish`/`REG_POSTFLG` 字节写入，同时加入两次 SPI 事务。 | **[D/T/E]** normal 与 V3 相同；stealth 改变 warm/保留固件交接、跳过 PWM 黑→白渐变并保留 P1 Alpha 范围未修改，实机确认其白屏后显示健康提示。新增 SPI 序列。 |
| V5 | 改变主 P1/P2 交接槽布局，并将主 P2 读取的次级 FH 从 `0x3FC80` 移至 `0x3F680`；其他 FP normal/stealth 行为保持 V4 风格。 | **[D/H]** 使用新的主元数据/交接位置，并进入安装器的 `H=2` / `FH+3` V5+ 版本识别方案；历史研究将该迁移归因于避免覆盖末尾 Wi-Fi 接入点设置。 |
| V6 | 恢复 FP1 的 `SVC_CustomPost`/`REG_POSTFLG` 写入，增加条件 FP1 清除/复制；在 SPI 序列前恢复 `SignalBootFinish`；安装器 V5+ 子版本字段递增为 `3`（V6）。 | **[D]** 发生上述 FP1 内存准备及 FP2 调用顺序变化。此 FlashMe V6 Phat 线仍嵌入任天堂 V3 保留基底。 |
| V7 Old | FP 前置区增至 `0x400`，改变 FP1 IPC 阶段，引入 Phat/Lite 家族，并在 FP2 加入可到达的 Slot-1 头装载器。 | **[D/T]** 加入直接的卡带头验证及 ARM9/ARM7 启动；Lite 用任天堂 V6 P1/P2/P3 偏移，Phat 用任天堂 V3 偏移。 |
| V7 New | 保持 V7 Old Lite FP 前置代码不变；改变 Phat FP2 在 stealth cold 路径中的 SPI 设置/响应处理与 SPI 写帮助程序。 | **[D]** 在已分析前置代码内，仅所列 Phat 设置/等待行为改变。 |
| V8 | 加入 `BuildNoAuto`；移除到 V7 FP2 辅助/卡带装载器的所有入口路径调用，但保留其不可达帮助程序字节；把用户设置读取/选择移入保留固件路径；改变 Lite normal 保留固件节奏。 | **[D/T]** V8 noauto 要求 A+B+X+Y，normal V8 不再能从入口路径到达 V7 FP2 Slot-1 装载器，normal V8 Lite 则以一次延迟替代此前 FP2 的 PWM 背光渐亮。 |
| V8a | 用命令驱动的准备阶段和标准 Slot-1 NDS 程序装载器替换主 P1/P2；将 noauto 触发改为 Select；在 FP1 cold 准备中清显示控制。 | **[D/T]** Start+Select/`BOOT` 进入 V8a 主替代路径。经 BIOS 维护的 Slot-1 头有效性测试后，它要么走旧 Slot-2 跳板，要么以标准 `B7` 数据读取和头内 ARM9/ARM7 字段将两个 CPU 交接至 Slot-1 NDS 程序；V8a noauto 的 Select 会选择 FlashMe。 |

## 仍未确定的事实

下列问题被刻意保留为开放问题，而不强行归入某项功能名称：

- **V1 已引入且后续保留的** P3 状态 `0x0C` Nintendo Logo 闸控状态转换（写入状态值
  `0x0D`）到底对应哪个用户可见的任天堂画面/状态。控制流已经明确，但仅根据这一局部
  改动，尚不足以确认 V1 实际移除了“健康/安全画面”。
- **V3 才新增的** normal 保留 P1 副屏 Alpha 转场范围，究竟对应哪个用户可见画面，以及它是否
  与前述 V1 P3 状态修改共同构成同一显示策略。寄存器与局部控制流已经明确，但不能把两处改动
  自动合并为一项已经证实的健康屏补丁。
- 主 P2 流式固件解码路径的高层策略目的。其串行 `READ`、LZ77 回调 ABI、FP1/FP2 字段使用
  及交接均已确定；但作者是将其视为服务、恢复还是普通启动回退，仍不能仅凭代码
  断言。
- V7 辅助 `0xF2`/`0xF1`/`0xF0` 命令及 Phat/Lite SPI 设置响应位的高层协议意义。命令字节、
  条件分支和之后的装载动作均已确认，但外设协议的作者级目的尚未确认。
- V8a 为什么通过 **Start+Select** 与 `BOOT` Game Code 暴露标准 Slot-1/Slot-2 替代启动选择。
  其头有效性测试、数据传输及双 CPU 交接均已明确；尚未证明的只有作者的策略动机。
- V6 及以后 FP1 为什么会在 BIOS7 标记 Slot-1 头无效后合成“空白头前缀 + BIOS Logo”，而保留
  P3 的 Logo 比较分支又被独立强制走成功状态。触发条件及生成的 RAM 布局已经明确，但更大的
  保留内存策略用途尚未确定。

## 证据参考

- [任天堂 V3/V6 语义映射](../official/SEMANTIC_MAP.zh-cn.md)：本文使用的准确运行时位置、
  源标签以及 P1/P3 字节级改动。
- [任天堂清单导出说明](../official/README.md)：已恢复的 P1–P5 运行时范围，其中包括补丁
  源码所用的 P3 基址验证。
- [GBATEK](https://doc.kodewerx.org/documents/gbatek.html)：NDS I/O、IPC、BIOS、按键、SPI
  与卡带接口参考。
- [libnds 按键定义](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/input.h)
  与[按键扫描实现](https://raw.githubusercontent.com/devkitPro/libnds/master/source/arm9/keys.c)：
  低有效按键解释。
- [libnds 视频定义](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/arm9/video.h)
  与 [ARM7 串行定义](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/arm7/serial.h)：
  显示与 SPI 常量命名；触摸控制器命令语义直接采用 GBATEK。
- [libnds NDS 头布局](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/memory.h)
  与[卡带定义](https://raw.githubusercontent.com/devkitPro/libnds/master/include/nds/card.h)：
  V7 FP2、V8a P2 卡带装载器使用的字段偏移。
- [dsfwtool 组件/布局资料](../../dsfwtool/README_ZH.md)：对 H/P1–P5/FH/FP1/FP2 存储层及
  P12/P345 处理方式的独立交叉核对。
- 随附 [BIOS7 清单](../../ndsbios/bios7.s) 与 [BIOS9 清单](../../ndsbios/bios9.s)：本文使用的
  本地 SVC 表和私有 BIOS 入口行为核验来源。

外部文档仅用于命名硬件与 ABI 字段。本文关于各 FlashMe 版本的全部主张均以本地重建的
汇编为基础，而非历史发布说明。
