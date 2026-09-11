# FlashMe V1–V8a：源码级变更记录

本文是 FlashMe 自制固件的版本分析，不是任天堂 NDS 固件版本史。本文把已提取模板所重建的
ARMIPS 源作为主证据：每一项结论都应能回到具体的 P1、P2、FP1、FP2 或头部补丁中检查，
而不是只复述发布帖。

## 证据标记与资料边界

- **[S] 源码证据**：重建汇编中的实际指令、条件分支和布局。例如
  [V8a Phat P1](v8a/phat/src/patch_p1.s) 的命令循环，以及
  [V8a Phat P2](v8a/phat/src/patch_p2.s) 的恢复/卡带读取路径。
- **[B] 模板证据**：从安装器提取的镜像与布局；见
  [manifest.csv](../extracted/manifest.csv) 和 [layout.csv](../extracted/layout.csv)。
  它们能证明镜像内容与位置，不能单独证明作者意图。
- **[R] 发布资料**：仅补充发布者或当时社区对目标的描述，不替代源码分析。
- **[I] 推断**：代码显示行为、但没有原作者说明目的时，会明确标注为推断。

### V2：历史记录驱动的推断性重建

没有可用的原始 FlashMe V2 载荷可供逐字节分析。资料集内的
`resource/flashme_v2.nds` 与 `resource/flashme_v3.nds` 同为
`45330638f608f9c1668f95962e0229adb88184ee062944e447d8c6b65e953b86`，因此它们及
由其导出的“V2”模板被明确排除为 V2 证据。**本项目的 [v2](v2) 是功能性推断重建，
不是找回的 V2，不得视为历史原件或字节一致结果。**

**[R] 同期论坛记录。** 2005-05-24，headspin 将 V2 描述为“V1 加上直接启动
`.ds.gba` 时移除健康屏幕”及“后续更新不再需要短接 SL1”；同一段将背光渐亮、无健康
屏幕及取消 WMB RSA 签名检查列为 V3 项。紧邻的 FourScience 回帖说其 V1 升级至 V2
时已显示不必再短接 SL1，并称其保存过数日网页及文件。这两条都应作为历史旁证阅读：
headspin 明说内容出自其理解，FourScience 是当时用户的缓存陈述，均不是 V2 发布包。

- [Wayback：post 43567（截图所示记录）](https://web.archive.org/web/20150811075617/https://forum.gbadev.org/viewtopic.php?p=43567)
- [静态 gbadev 论坛存档：thread 5419](https://gbadev.net/forum-archive/thread/19/5419.html)

**[S/I] 结构约束。** 已知 FlashMe V1、V3 Phat 镜像在 `0x00000--0x0FFFF` 完全一致。
这与“V2 后续更新可免 SL1”相容：初次写入时可建立一个与 V3 相同的保护区，随后版本
只需写保护区后的部分。它不能反过来证明历史 V2 的每个字节，但足以作为 V2 重建的布局
约束。因此 V2 使用 V1 的其余基础行为、FP1/FP2 ROM 布局，并固定前 `0x10000` 为与
V3 相同的内容。

## 共同架构

FlashMe 是两级、双 CPU 交接，而不是单一组件补丁：

    主头 H
     ├─ P1：一级 ARM9（等待、跳转，或 ARM9 冷启动准备）
     └─ P2：一级 ARM7（选择路径、读取 FH、放行 P1）
           ↓
    FlashMe 头 FH
     ├─ FP1：二级 ARM9 前置代码 + 保留的来源 P1 主体
     └─ FP2：二级 ARM7 前置代码 + 保留的来源 P2 主体
           ↓
    保留主体继续运行；P3 验证补丁允许其接受已改写的组件

- P2 是一级策略拥有者；早期 P1 只是 P2 可改写的等待/跳转槽，直到 V8a 才变成明确的
  ARM9 命令执行器。
- FP2 先决定服务路径或 FlashMe 冷启动路径，再用 IPC_SYNC 阶段值驱动 FP1，因此两颗
  CPU 不会独立选出冲突的路径。
- FP1/FP2 的新前置代码放在保留主体之前；保留主体仍位于原有 RAM 入口，因而能保留
  绝对地址假设。各版本的 symbol.inc 都以
  FlashMeFp1RamAddress = RetailP1RamAddress - FlashMePrefixBytes 表达这一关系。
- [V1 P3](v1/src/patch_p3.s) 是验证兼容层：+0x13ED0 直接令 RSA-1024/SHA-1 验证成功，
  +0x173C0 直接令 SHA-1 比较成功，+0x1019C 强制后续状态写入。P4/P5 在此补丁族中
  保持原样。

## 布局演变

| 系列 | FP 前置区 | FH 镜像地址 | H / FH 的 +0x17C 标记 | 源码可确认的意义 |
| --- | ---: | ---: | ---: | --- |
| V1–V4 | 0x200 | 0x3FC80 | 1 / 1 | 早期双头、两级交接。 |
| V5 | 0x200 | 0x3F680 | 2 / 2 | FH 左移 0x600；P1 成为纯等待门。 |
| V6 | 0x200 | 0x3F680 | 2 / 3 | 改写二级冷启动和 ARM9 返回协议。 |
| V7 Old / New | 0x400 | 0x3F680 | 2 / 4 | 前置区扩大，IPC 从 B/C/D 改为 B/C/E。 |
| V8 / V8a | 0x400 | 0x3F680 | 2 / 5 | 保持 V7 布局；V8 改二级策略，V8a 改一级恢复。 |

这些值来自各版本的 patch_h.s、patch_fh.s、symbol.inc，是 FlashMe 自己写入的头标识，
不能称作任天堂固件版本号。

## 按版本的代码变化

### V1：早期两级引导基线

**[S] 一级。** [V1 P1](v1/src/patch_p1.s) 保留一条继承的 ARM9 写入，再读取 P1 + 0x0C
的可变字并 BX 跳转；该字初值令 ARM9 停在循环中。[V1 P2](v1/src/patch_p2.s) 是唯一
写入该续接槽的一端：它先处理 Slot-2 兼容路径，否则读取 FH 所描述的 FP1/FP2，然后
放行 P1。

**[S] 二级。** [V1 FP2](v1/src/patch_fp2.s) 读取低有效按键和 Slot-2 标题：Select 选
服务路径，A+B+X+Y 或 DSBooter/PASS 选 FlashMe 路径，并发布 B、C、D IPC 阶段。
[V1 FP1](v1/src/patch_fp1.s) 仅消费结果：B 返回保留 ARM9 主体；C 清理 ARM9 可见的
DMA/显示/WRAM 状态，等到 D 再安装返回跳板。

这已经建立了后续版本持续使用的分工：ARM7 决策、ARM9 准备、IPC 与共享 P1 槽同步。

### V2：V1 基线上的最小健康屏幕路径推断

**[I/S]** [V2 FP1](v2/src/patch_fp1.s) 只加入两处标明为推断的保留 P1 修改：

1. `+0x2DC` 是状态 0 的有符号半字跳转表项。V1 的 `0x0017` 指向已有 `+0x0AAC`
   处理程序；V2 写入 V3 已使用的 `0x0023`，转到已有的 `+0x0884` 替代启动状态；
2. `+0x8CE` 的无条件分支改为零值 Thumb NOP，使该替代状态能够进入已有的状态处理。

V2 **不**采用 V3 的 `+0x89E`、`+0x8BA` 两处 `0x0F → 1` 计时门变化，保留 V1 的
FP2（包括完整 `DSBooterPASSFLSH` 签名）、P3 和其 WMB/RSA 行为；也保持 V1 的
FP1 `0x29FA8`、FP2 `0x36AC8` 布局。这样将论坛所述的 V2 功能限制为“健康屏幕路径
跳过 + 后续免 SL1 的布局前提”，而不误带 V3 的缩短显示时序、FP2 布局或额外策略。

这不是对原始 V2 字节的断言。它是以已验证的 V1/V3 状态机差异为边界、可复查且可构建的
中间版本模拟；详见 [V2 README](v2/README.md)。

### V3：增加保留 P1 的兼容修改

**[S]** V3 相比 V1 的实质变化集中在 [V3 FP1](v3/src/patch_fp1.s) 的保留主体：

1. +0x2DC 的状态 0 跳转表半字由 `0x0017` 改为 `0x0023`，将已有处理程序从
   `+0x0AAC` 重定向到 `+0x0884`；它不是一条寄存器传递指令；
2. +0x89E 与 +0x8BA 的两个计数门槛由 0x0F 改为 1；
3. +0x8CE 的无条件跳转被移除，使代码顺序落入后续状态处理；
4. 继续保留 V1 已有的 +0x6DE6、+0x6E3C 两处条件回调强制落入。

这些都是前置代码之后、保留主体固定偏移处的 Thumb 替换。因此能确认 V3 改了分派数据流、
初始化门槛及回调落入，但不能仅凭这些指令给每处强行命名某个高层功能。

**[S]** [V3 FP2](v3/src/patch_fp2.s) 还把储存的 Slot-2 签名从
DSBooterPASSFLSH 缩成 DSBooterPASS。判定本来只检查 DSBooter 的前 8 字节或 PASS 的
4 字节，所以这是布局压缩，不是标题识别策略变更。

### V4：Stealth 成为实际代码分支

**[S]** [V4 Makefile](v4/Makefile) 首次向汇编传入 BuildStealth；
[V4 FP1](v4/src/patch_fp1.s) 和 [V4 FP2](v4/src/patch_fp2.s) 都有条件分支。因而
Normal/Stealth 不只是安装器文件名不同：

- B 服务路径中，Normal 恢复电源状态并等待 D；Stealth 直接进入保留 P1/P2，跳过 B→D
  时序。
- Normal 使用 V3 的六处保留 P1 修改；Stealth 仅保留两处回调强制落入修改。
- 冷启动中，FP1 移除之前的 ARM9 自定义 SWI；FP2 把早期的 BIOS 返回调用换成
  0x8A00/0x84、0x8200/0 两次明确的 SPI 写入。

所以“Stealth 保留健康警告”只是表层策略；源码还显示它改变了服务时序、保留主体补丁
集合与冷启动外设准备。

### V5：一级等待门与尾部重排

**[S]** [V5 P1](v5/src/patch_p1.s) 删除 V1–V4 入口处的继承写入，变成纯等待门；
可变续接字由 P1 + 0x0C 移到 P1 + 0x08，初值指回 P1 自身。P2 的两条路径都写新槽，
使“等待—放行”协议更小、更单纯。

**[S/B]** [V5 symbol.inc](v5/include/symbol.inc) 将 FH 从 0x3FC80 移到 0x3F680，
并把 H/FH 标记从 1/1 改为 2/2。[layout.csv](../extracted/layout.csv) 显示新的 FH
恰好在 0x3F800 结束，不再占用随后的尾部区域。源码能确认重排本身，不能单独证明动机。

**[R]** 后来的 FlashMe 技术资料把该移动与避免网络/Wi-Fi 设置覆盖早期尾部内容联系
起来；它与实际左移 0x600 相符，但历史原因仍只是旁证，不是从 P1 指令直接推出的结论。

### V6：二级冷启动和返回跳板重写

**[S]** [V6 FP1](v6/src/patch_fp1.s) 在冷启动中重新调用 ARM9 BIOS 服务，检查
FirmwarePart1RamaddrBase - 4 的标志；标志非零时清理附近区域并调用 CpuFastSet。
它还把原有返回上下文改为 0x027FFF70 的两指令 ARM9 跳板：先发布 D，再经保存的 ARM9
返回槽加载 PC。

**[S]** [V6 FP2](v6/src/patch_fp2.s) 入口保留 mov r0, #6，并在最终
0x8A00/0x84、0x8200/0 SPI 对之前重新调用 BIOS 返回服务。FH 标记由 2 改为 3，
H 仍为 2。

这里能确认的是 ARM9/ARM7 会合协议被实质改写；现有代码没有说明“修复了哪一台机器或
哪个故障”，因此不把它杜撰成具体 bug 修复。

### V7 Old：E 会合、可达的 AUX SPI 路径、Lite 分支

**[S]** [V7 Old Phat symbol.inc](v7_old/phat/include/symbol.inc) 把 FP 前置区扩大为
0x400，FH 标记改为 4。FP1/FP2 的 IPC 从 B/C/D 改为 B/C/E：
[V7 Old FP1](v7_old/phat/src/patch_fp1.s) 在常规 B 路径等待 E，冷启动返回跳板也以 E
作为会合信号。

**[S]** [V7 Old Phat FP2](v7_old/phat/src/patch_fp2.s) 有一条实际可达的辅助 SPI/卡带
路径：非标题路径发送 F2，检查 0x32、0x10 响应，再发送 F1；成功后经 AUX SPI、GCDATAIN
和 DMA 分块读取数据，并复用冷启动续接；失败则发送 F0 并回落服务路径。这不是为了布局
保留的死代码。

**[S]** Lite 也不仅是换组件来源。[V7 Old Lite FP2](v7_old/lite/src/patch_fp2.s) 在
最终 0x8A00/0x8200 SPI 命令对之前运行两步 SPI 设置；返回状态 bit 6 决定是否从
FH + 0x64 取低位设置。因此 Phat/Lite 具有不同的外设准备代码。

**[R]** V7 Lite 发布资料把用户可见目标称为 DS Lite 亮度支持。源码能证明独立 Lite
SPI 流程，但不能只凭一个寄存器事务把每个位严格等同为“亮度”，两类证据需分开阅读。

### V7 New：Phat Stealth 的 SPI 调整与双模板包装

**[S]** 相对 V7 Old Phat，[V7 New Phat FP2](v7_new/phat/src/patch_fp2.s) 的核心新增
在 Stealth 冷启动：先以 0x8802、0x8002 进行两步 SPI 事务，读取返回状态，必要时把
FH + 0x64 的高半字节并入设置，再发送最终 0x8A00/0x8200 对。SPI 写入帮助例程也改为
等待传输完成并读取返回值。

**[S/B]** 当前重建中，V7 Old Lite 和 V7 New Lite 没有发现对应的新分支主体；V7 New
的实质代码变化集中于 Phat FP2。[manifest.csv](../extracted/manifest.csv) 则表明
V7 New 单个安装器可提取 Phat/Lite 两套模板，而 V7 Old 的 Phat 与 Lite beta 来自分开
的安装器。这是包装方式变化，不能误写成 Lite 前置代码重新设计。

### V8：移除可达 AUX 路径，加入 NoAuto

**[S]** [V8 Phat FP2](v8/phat/src/patch_fp2.s) 保留了 V7 的 AUX SPI/卡带帮助块，
但路由选择器不再调用它们；普通分支直接回到服务路径。相较 V7 Old 中可达的 F2/F1/F0
探测，V8 中这些块只为维持前置区和字面量池布局而存在。

**[S]** V8 还将 FH 复制提取为公共函数，服务路径也先复制 FH。Phat 冷启动不再运行
V7 New Stealth 的两步设置，只做 BIOS 返回准备和最终 SPI 写入。Lite 不同：
[V8 Lite FP2](v8/lite/src/patch_fp2.s) 在所有变体复制 FH 时都运行两步 Lite SPI 设置，
常规 B 路径使用 BIOS 循环延时，而非 Phat 的 IPC 时序循环。

**[S]** V8 首次出现 BuildNoAuto。NoAuto 仅接受低有效 A+B+X+Y 选择 FlashMe，主动跳过
Select 与 DSBooter/PASS 自动识别；标题测试块仍在镜像中但不可达。Normal/Stealth 的
B/C/E 握手并不因此改变。

**[R]** 同期 V8 发布资料把这组变化称为移除有问题的 MK2/3 启动代码，并说明 No-auto。
安装器的声音提示属于安装程序端，不在此处分析的已安装 P1–FP2 载荷内，不能误写成
V8 启动前置代码新增的音频驱动。

### V8a：一级恢复路径变为命令协议

**[S]** [V8a Phat P1](v8a/phat/src/patch_p1.s) 不再是 V5–V8 的纯等待门。P1 + 4
是命令字：

- 0：继续等待；
- 1：清理 DMA、显示、VRAM、OAM、调色板、WRAM 与两个控制字，完成 ARM9 冷启动准备后
  清零命令；
- 其他值：当作 ARM9 续接地址直接 BX 跳转。

**[S]** [V8a Phat P2](v8a/phat/src/patch_p2.s) 成为一级策略中心。它检查 KEYINPUT 的
Select/Start 两位是否都低有效，或 BOOT 标记是否匹配；满足时走恢复/卡带路径：先向
P1 写命令 1，复制头部、准备 SPI、等待 P1 清零，再以 0x200 字节块读取卡带数据并跳入
恢复续接。普通路径仍解码描述符并把 ARM9 续接写到 P1 + 4。

**[S]** 二级 FP1/FP2 保持 B/C/E，但 [V8a Phat FP2](v8a/phat/src/patch_fp2.s) 改写了
NoAuto 语义：NoAuto 仅在 Select 按下时进入 FlashMe；V8 的 NoAuto 则要求 A+B+X+Y。
常规变体仍由 Select 请求服务路径，A+B+X+Y 或 DSBooter/PASS 请求 FlashMe。

V8a 保持 V8 的 0x400 前置区、0x3F680 FH、2/5 标记，却把最早阶段从“P2 放行一个等待槽”
升级为“P2 向 P1 发命令并等其完成”。这是 V8a 最重要、可由源码直接确认的架构变化。

## 变体和机型差异

| 项目 | 代码实际行为 |
| --- | --- |
| Normal | 保留服务时序；按键和 Slot-2 标题可参与路径选择。 |
| Stealth | 不只是健康警告策略名：B 路径会直接进入保留主体，且若干版本使用不同的 FP1 补丁集合或 SPI 设置。 |
| V8 NoAuto | 仅 A+B+X+Y 选择 FlashMe，跳过 Select 与标题自动识别。 |
| V8a NoAuto | 仅 Select 选择 FlashMe；与 V8 的按键语义不同。 |
| Phat / Lite | 两者是独立模板与保留主体组合；Lite 还有两步 SPI 准备和不同服务延时，不只是换头标记。 |

## 历史资料旁证

以下链接只用于解释发布背景，前文的技术结论以源码和提取模板为主：

1. [FlashMe V8 release post](https://www.1emulation.com/forums/topic/21882-flashme-v8-released/)：
   No-auto、MK2/3 路径移除、安装器声音提示。
2. [V7 DS Lite release report](https://game.17173.com/content/2006-05-17/20060517181212961,1.shtml)：
   V7 Lite 的亮度支持及 beta/正式发布背景。
3. [FlashMe page snapshot](https://web.archive.org/web/20110302112411/http://home.comcast.net/~olimar/flashme/)：
   V8a 的变体、按键策略和恢复使用说明。
4. [Pineight technical history](https://pineight.com/ds/pass/) 和
   [GBASP FlashMe history](https://gbasp.ru/flashme-en.html)：
   V5 尾部布局变动的历史背景；两者都是后来的技术回顾，而非逐条原始提交记录。
