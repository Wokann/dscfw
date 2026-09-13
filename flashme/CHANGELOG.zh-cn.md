# FlashMe 版本变更记录

[English](CHANGELOG.md)

## 各版本的功能变化

### V1

- **启动 Slot-2 的 DS 程序。** 若 Slot-2/GBA ROM 的 Game Code 为 `PASS`，或Game title以 `DSBooter` 开头，开机时FlashMe便会自动将其视作DS程序进行启动。即使 Slot-2 头不带这两个标识，仍可按住组合键 `A+B+X+Y` 强制启动。
- **启动 原始官方固件。** 开机时，按住 `Select` 会进入原始官方固件。
- **启动 救砖保护。** 若 Slot-2/GBA ROM 的 Game Code 为 `BOOT` ，或按住组合键 `A+B+Start+Select` ，可以在开机时强行启动slot2端的DS程序。由于这段代码位于固件的非常前面，所以固件刷写中途出问题时，只要这部分数据已经刷入，或已经刷入FlashMe但固件受SL1的0x10000保护区之外的数据被损坏，那么都可以通过本途径强行启动 Slot-2 端程序进行重新刷写固件。
- **移除 Wireless MultiBoot 校验。** 移除了Wireless MultiBoot（如Download Play）的RSA校验检测。
- **原固件的开屏渐变。** 启动原官方固件情况下，开屏为从黑到白的渐变，随后展示健康提示。（slot2的ds模式直接白屏显示进入对应游戏或烧录卡）。
- **基底固件。** 基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。 

### V2

- V2 的原始镜像尚未找到备份。论坛相关资料关于V1-V3的版本功能变更也存在误差，故无法尝试功能性复现。
- **V1-V2升级无需短接。** flashme的版本变动尽可能保证存放在固件前部的修改内容不做变动，只在后部进行变动。这样只有在官方固件到flashme固件第一次刷写时，需要短接SL1解除前0x10000的保护。后续版本更新只要前0x10000未变化，即可以无需短接就能更新固件数据。（该信息已由论坛实测记录确定可信）
- **基底固件。** 基于官方ds phat v3固件进行修改。

### V3

- **移除 健康提示。** 启动原官方固件情况下，开屏为从黑到白的渐变，随后不再展示健康提示了。
- **V1-V3升级无需短接。** V1-V3前0x10000范围相同，无需短接即可更新。
- **基底固件。** 基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。

### V4

V4 针对健康提示的显示与否，分别制作两个独立版本normal和stealth：

- **独立版本 normal**：移除健康提示，同时保留启动原固件时的开屏渐变。
- **独立版本 stealth**：保留健康提示，同时移除开屏渐变。隐身，寓意隐藏本机被刷过机的事实。

其他改动:
- **V1-V4升级无需短接。** V1-V4前0x10000范围相同，无需短接即可更新。
- **基底固件。** 基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。
- V4 在代码中存在一次触摸屏控制器 SPI 操作，但代码没有使用返回值，尚无法确定其用途。

### V5

- **双版本发布**：维持两个独立版本normal和stealth的发布。
- **wifi设置区域修复**：V1-V4中，flashme的二次引导文件头占用了后来被用作为记录wifi接入点数据的地址范围。这导致第一款支持wifi的《马里奥赛车》发布后，刷写过旧版本flashme的玩家会出现砖机情况。V5 将二次引导文件头占用范围往前挪动，避让开了这部分数据。
- **V1-V4升级到V5需要短接**：V5的前0x10000发生了改变，V1-V4的主机必须短接后才能更新升级。
- **安装器内部版本分类更新**：flashme.nds内部将V1-V4视为同一类版本，在固件文件头的0x17C的位置记录为1（分类1），在固件末尾的二次引导文件头的0x17C的位置也记录为1（固定1）。V5起，固件文件头的0x17C的位置记录为2（分类2），二次引导文件头的0x17C的位置值记录为2（该数值+3=当前版本号）。固件文件头的0x17C的位置记录为3（分类3）时代表hbfirmware自制固件，二次引导文件头的0x17C的位置值记录为0xFF。
- **基底固件。** 基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。

### V6

- **内部逻辑优化**：理论上无使用上明显可见的功能性变化。
- **V5-V6升级无需短接。** V5-V6前0x10000范围相同，无需短接即可更新。
- **基底固件。** 基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。

### V7 Old Phat

- **NeoFlash MK2,MK3支持**：支持直接从flashme启动slot1端的MK2，MK3烧录卡(DSLINK也可被引导)。
- **V5-V7 old phat升级无需短接。** V5-V7前0x10000范围相同，无需短接即可更新。
- **基底固件。** 基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。

### V7 Old Lite

- **lite机型版本发布**：DS phat、DS lite属于不同类型的硬件，官方固件也有差异，故V7开始额外创建lite版本的固件，论坛显示lite曾经有beta1、beta2两个测试版本，但目前本仓库只寻找到一种版本，疑似是beta2，因为本仓库收录的，来自v7 lite版独立安装器的固件镜像，与V7 New集成版安装器内的lite版本的固件镜像，数据完全一致。
- **NeoFlash MK2,MK3支持**：支持直接从flashme启动slot1端的MK2，MK3烧录卡(DSLINK也可被引导)。
- **V5-V7 old lite升级需要短接。** lite与phat版本存在功能上的一定差异，比如背光等功能，但也可强行刷写在phat机型上。由于修改的基底固件不同，所以前0x10000范围必然不相同，若要强行刷写必须进行短接。其中CPU20主板的phat机型拥有和lite相同的电源管理控制芯片，所以刷入lite固件后，可以拥有和lite一样的4级调光能力。
- **基底固件。** 基于官方ds lite v6（USG-WORLD WIDE-Ver2.0）固件进行修改。

### V7 New

- **安装器集成双机型版本**：从此版本开始，flashme.nds内置phat和lite两种固件，通过对电源管理芯片的判断来区分当前设备是phat或lite。也因此CPU20主板的phat会被识别为lite，从而获得四级调光功能。
- **NeoFlash MK2,MK3支持**：支持直接从flashme启动slot1端的MK2，MK3烧录卡(DSLINK也可被引导)。
- **phat路线：V5-V7升级无需短接。** V5-V7的phat版本，前0x10000范围相同，无需短接即可更新。但是跨机型刷写必须短接。
- **基底固件。** phat基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。lite基于官方ds lite v6（USG-WORLD WIDE-Ver2.0）固件进行修改。

### V8

V8 针对slot2卡带自动启动与否，在原基础上制作出了noauto分支，该分支依旧包含normal和stealth：

- **normal**： 保留 `PASS`/`DSBooter` 自动选择，及组合键 `A+B+X+Y` 的强制进入 FlashMe。移除健康提示。
- **stealth**： 保留 `PASS`/`DSBooter` 自动选择，及组合键 `A+B+X+Y` 的强制进入 FlashMe。保留健康提示。
- **noauto**：关闭 `PASS`/`DSBooter` 自动选择；必须按住 `A+B+X+Y` 手动进入 FlashMe。移除健康提示。
- **stealth_noauto**：关闭 `PASS`/`DSBooter` 自动选择；必须按住 `A+B+X+Y` 手动进入 FlashMe。保留健康提示。
- **启动 原始官方固件。** 开机时，所有版本均为按住 `Select` 会进入原始官方固件。
- **lite版本开屏渐变移除**：normal（含新增noauto）自V3起在进入原固件情况下的黑到白渐变，现在变为固定白屏显示。stealth（含stealth_noauto）版本维持V4起原设定固定无开屏渐变。phat版本维持自V4起的设定。
其他改动：
- **移除 NeoFlash MK2,MK3支持**：不再支持MK2，MK3烧录卡（含DSLINK）的启动。在不进入slot2卡ds模式时，程序会向slot1卡带发送一个信号探测判断是否是MK2、MK3类卡带来决定后续是否启动。这个探测信号使非目标卡带出现不可预测响应。推测由于这个原因移除了支持。
- **phat路线：V5-V8升级无需短接。** V5-V8的phat版本，前0x10000范围相同，无需短接即可更新。但是跨机型刷写必须短接。
- **lite路线：V7-V8升级无需短接。** V7-V8的lite版本，前0x10000范围相同，无需短接即可更新。但是跨机型刷写必须短接。
- **基底固件。** phat基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。lite基于官方ds lite v6（USG-WORLD WIDE-Ver2.0）固件进行修改。

### V8a

- **normal**： 保留 `PASS`/`DSBooter` 自动选择，及组合键 `A+B+X+Y` 的强制进入 FlashMe。移除健康提示。
- **stealth**： 保留 `PASS`/`DSBooter` 自动选择，及组合键 `A+B+X+Y` 的强制进入 FlashMe。保留健康提示。
- **noauto**：关闭 `PASS`/`DSBooter` 自动选择；必须按住 `Select` 手动进入 FlashMe。移除健康提示。
- **stealth_noauto**：关闭 `PASS`/`DSBooter` 自动选择；必须按住 `Select` 手动进入 FlashMe。保留健康提示。
- **启动 原始官方固件。** 开机时，按住 `Select` 会进入原始官方固件。（noauto两版本无需按键即可进入原始官方固件，设定为按住 `Select` 后进入FlashMe）。
- **救砖保护变动。**：救砖组合键由 `A+B+Start+Select` 变更为 `Start+Select` 。按住组合键 或 Slot-2/GBA ROM 的 Game Code 为 `BOOT` 时，将尝试对slot1卡带或slot2卡带进行强制启动。
- **phat、lite路线：V8a以下版本升级到v8a均需要短接。** v8a的phat和lite的前0x10000范围，与v8及以下的所有版本均不同，升级必须短接刷写固件。
- **基底固件。** phat基于官方ds phat v3（NTR-WORLD WIDE-Ver3.0）固件进行修改。lite基于官方ds lite v6（USG-WORLD WIDE-Ver2.0）固件进行修改。




## 组合键变化一览表

| 版本 | 机型 | 变体 | 强行进入slot2组合键 | 强行进入官方固件组合键 | 早期启动组合键（通常救砖用） |
| --- | --- | --- | --- | --- | --- |
| `v1` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` 
| `v2` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
| `v3` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
| `v4` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `phat` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
| `v5` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `phat` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
| `v6` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `phat` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
| `v7_old` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `phat` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `lite` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `lite` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
| `v7_new` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `phat` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `lite` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `lite` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
| `v8` | `phat` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `phat` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `phat` | `noauto` | `A+B+X+Y` | 无需 | `A+B+Start+Select` |
|  | `phat` | `stealth_noauto` | `A+B+X+Y` | 无需 | `A+B+Start+Select` |
|  | `lite` | `normal` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `lite` | `stealth` | `A+B+X+Y` | `Select` | `A+B+Start+Select` |
|  | `lite` | `noauto` | `A+B+X+Y` | 无需 | `A+B+Start+Select` |
|  | `lite` | `stealth_noauto` | `A+B+X+Y` | 无需 | `A+B+Start+Select` |
| `v8a` | `phat` | `normal` | `A+B+X+Y` | `Select` | `Start+Select` |
|  | `phat` | `stealth` | `A+B+X+Y` | `Select` | `Start+Select` |
|  | `phat` | `noauto` | `Select` | 无需 | `Start+Select` |
|  | `phat` | `stealth_noauto` | `Select` | 无需 | `Start+Select` |
|  | `lite` | `normal` | `A+B+X+Y` | `Select` | `Start+Select` |
|  | `lite` | `stealth` | `A+B+X+Y` | `Select` | `Start+Select` |
|  | `lite` | `noauto` | `Select` | 无需 | `Start+Select` |
|  | `lite` | `stealth_noauto` | `Select` | 无需 | `Start+Select` |
|  |  |  |  |  |  |

