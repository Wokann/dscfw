# FlashMe 版本变更记录

[English](CHANGELOG.md)

## 范围与阅读方式

本文以面向使用者的方式记录已恢复的 FlashMe V1、V3–V8a 代码行为。结论主要来自已重建的
汇编及其修改的任天堂 V3/V6 代码，而不是把旧发布页文字直接当作证据。下文的“已确认”表示
分支、数据流或硬件动作可从代码中直接看到；明确标出的不确定项不应被误读为缺失功能。

本源码树不分发任天堂固件或原始 FlashMe 镜像。这里没有可用的 V2 原始镜像或源码，因此不对
V2 作重建，也不作功能断言。

## 从 V1 起持续存在的行为

已恢复的 V1 已具备 FlashMe 的主要设计；除非下方版本条目明确指出变化，后续版本均保留这些
行为：

- **启动 Slot-2 的 DS 程序。** 若 Slot-2/GBA ROM 的 Game Code 为 `PASS`，或标题以
  `DSBooter` 开头，便会自动选择 FlashMe 启动路径。即使 Slot-2 头不带这两个标识，仍可按住
  `A+B+X+Y` 强制选择该路径。
- **启动保留的任天堂固件。** 在普通选择器中，按住 `Select` 会选择保留的任天堂固件路径，
  而非 FlashMe 路径。
- **早期恢复入口。** `BOOT` Game Code 的判断早于 `PASS`/`DSBooter`；V1–V8 还会在按住
  `A+B+Start+Select` 时选择更早的替代路径。这是 Slot-2 恢复/刷写程序可利用的固件侧入口；
  真正修复受损固件的程序位于 FlashMe 外部。
- **放宽固件验证。** 保留的任天堂 P1/P3 中，组件完整性闸门被绕过；P3 的公钥格式化摘要和
  SHA-1 风格摘要比较入口固定返回成功。对使用者而言，这移除了受影响 NDS 程序路径上的那层
  任天堂签名验证阻碍。
- **normal 的启动呈现。** V1 normal 路径已经包含 PWM 背光渐亮；V1 尚不存在独立 stealth
  构建。

## 各版本的功能变化

### V1：已恢复功能的起点

V1 建立了完整的两阶段 FlashMe 装载器、Slot-2 自动与手动选择、早期恢复入口，以及上述验证
绕过。其 normal 路径也会执行背光渐亮。保留 P3 中有一处 Nintendo Logo/状态闸门被改动，但
仅凭代码无法命名它对应的精确任天堂 UI 场景；因此不能把它单独表述为已经严格证明的“健康
警告画面补丁”。

### V2：资料缺失

本仓库尚未找到 V2 的原始镜像或源码。它被刻意留空，而不是根据论坛回忆或相邻的 V1/V3 构建
进行模拟。

### V3：normal 启动显示过渡调整

V3 保留 V1 的核心行为，并在 normal 构建中新增四项对保留任天堂 P1 Alpha 转场路径的修改。
使用者会看到 normal 构建的启动显示过渡发生变化。代码能够证明 Alpha 分派、阈值和结束分支
被改写，但不能单独指出确切画面，因此本文不把 V3 宣称为首个已证实“移除某一健康警告画面”的
版本。

### V4：normal 与 stealth 分离

V4 首次引入后续版本沿用的两种面向使用者的启动呈现策略：

- **normal**：保留 V3 风格的转场修改与 normal 背光渐亮路径；
- **stealth**：不修改上述保留 P1 Alpha 字节，并跳过 normal 的 PWM 背光渐亮循环，保留通常
  与 FlashMe Stealth 关联的、较接近任天堂原始显示的启动路径。

V4 还在 FlashMe 路径中增加一次触摸屏控制器 SPI 操作，但代码没有使用返回值，无法从现有代码
可靠确认其另有独立的用户可见用途。

### V5：装载布局与安装器识别更新

相对 V4，未发现可确认的新终端用户启动控制。V5 修改了内部第一/第二阶段交接布局，并移动次级
头位置；它还开始使用 V5+ 安装器识别方案，因此兼容安装器可区分 V5+ 家族，而不是将其视为早期
不可细分的 FlashMe 类别。

### V6：修订早期启动准备

V6 保留 normal/stealth 选择，并修改冷启动准备：恢复写入启动完成标志，在特定条件下于 RAM
中准备标准 NDS 头/Logo 区域，并恢复 SPI 序列之前的一处调用顺序。这些都是明确的兼容性/初始化
改动，但现有代码尚未证明它们对应一项独立、可见的新用户功能。

### V7 Old：Phat/Lite 分支与额外匹配卡带启动路径

V7 Old 首次分出 Phat 与 Lite 构建。当常规 Slot-2 选择器没有选择 FlashMe 时，normal 路径可
探测一种辅助设备/卡带、验证其 NDS 头，并直接启动其 ARM9 与 ARM7 载荷。这是一条针对**匹配
设备**的额外启动路径，并非“可用来启动所有 Slot-1 卡带”的通用功能：其握手采用非标准命令，
仅凭现有代码还无法可靠确定目标硬件名称。

### V7 New：Phat stealth 的硬件协议修订

已恢复的 Lite 前置代码与 V7 Old 相同。V7 New Phat 则在 stealth 冷启动路径中修改 SPI 设置、
响应处理与写入辅助程序。这是确实存在的代码变化，但现有资料尚不能确定它的高层硬件目标或一个
独立的用户可见效果。

### V8：增加 noauto，并移除 V7 辅助卡带入口

V8 增加两个构建变体：

- **noauto**：关闭 `PASS`/`DSBooter` 自动选择；必须按住 `A+B+X+Y` 手动进入 FlashMe；
- **stealth_noauto**：同时采用 stealth 的启动呈现和 noauto 的手动选择策略。

normal 与 stealth 仍会自动识别 `PASS`/`DSBooter`。V8 同时移除了所有从普通 FP2 入口进入
V7 辅助/卡带装载器的路径，所以普通 V8 选择器不再尝试 V7 的匹配设备启动。V8 Lite normal
还以固定延迟取代之前的 PWM 背光渐亮循环。

### V8a：手动选择与标准卡带装载器更新

V8a 同时改变早期替代启动路径和 noauto 的控制方式：

- 早期替代路径改为 `Start+Select` 或更早的 `BOOT` Game Code 判断，取代 V1–V8 的
  `A+B+Start+Select`；
- **noauto** 与 **stealth_noauto** 中，按住 `Select` 即选择 FlashMe，取代 V8 的
  `A+B+X+Y` 要求；
- 主阶段新增基于标准 `B7` 命令的 Slot-1 NDS 装载器：当选中该路径时，会使用 NDS 头中
  ARM9/ARM7 的装载与入口字段；
- 冷启动准备还会清除主、副显示控制寄存器。

旧安装器元数据仍会把 V8a 报告为 V8。这只是 V5+ 识别方案无法区分两者的限制，不代表二者
行为相同。

## 构建变体速览

| 变体 | 面向使用者的策略 |
| --- | --- |
| `normal` | 本版本的标准 FlashMe 自动 Slot-2 选择与 normal 启动呈现。 |
| `stealth` | 使用更接近任天堂原始显示的启动路径，不采用 normal 的转场/渐亮修改。 |
| `noauto` | 不再自动因 `PASS`/`DSBooter` 进入 FlashMe；V8 需 `A+B+X+Y`，V8a 需 `Select`。 |
| `stealth_noauto` | 同时采用 stealth 启动呈现与 noauto 手动选择。 |

## 证据与限制

分支级证据、组件偏移、任天堂 V3/V6 语义映射与明确保留的未决问题，见
[FUNCTIONAL_ANALYSIS.zh-cn.md](FUNCTIONAL_ANALYSIS.zh-cn.md)。关于 RSA 的结论来自已恢复的
PKCS#1-v1.5 形状格式化摘要路径，并与 [RFC 8017](https://www.rfc-editor.org/rfc/rfc8017.html#section-8.2)
交叉核验；硬件寄存器解释则与 [GBATEK](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md)
交叉核验。
