# FlashMe V8a Lite 构建包

[English](README.md)

## 声明

本包仅包含 ARMIPS 源代码与 CRC 参考记录，不分发任天堂固件镜像或原始 FlashMe 镜像。

## 构建

将 <code>official_v6.bin</code> 放入 <code>dscfw</code> 仓库根目录后，在本目录运行
<code>make</code>。normal、stealth、noauto、stealth-noauto 四个构建默认均启用
TV-out，FP2 使用 TV-out 的 LZ-CUE P12 压缩规则；运行 <code>make variants</code> 可构建全部变体。

TV-out 的新 FP2 压缩流比 V8a Lite noauto 原流更短。存档的 IPS 补丁是在 V8a 基底上原位覆盖
新流制作的，因此有效流之后仍残留旧 FP2 数据。为字节还原该 noauto 镜像，构建会使用
<code>dsfwtool -b --no-stream-padding</code> 保留基底尾部；normal、stealth、stealth-noauto
不需要字节还原，故直接完整重建，不使用 <code>-b</code>。

## CRC-16/IBM

仅 <code>noauto</code> 具有固定 CRC-16/IBM 校验，范围为
<code>[0x000000, 0x3F800)</code>；其 IPS 原始 TV-out 值为 <code>0x1634</code>。
UTF-8 记录文件是存档参考，不会由构建创建或更新。其余三个变体只输出 BIN，并在终端显示
当前 CRC-16/IBM 值。noauto 的不匹配会在 BIN 生成后报告警告，不会令构建失败。

| 变体 | 输出 | CRC-16 行为 |
| --- | --- | --- |
| <code>noauto</code> | <code>flashme_v8a_lite_noauto_tvout.bin</code> | 固定 <code>flashme_v8a_lite_noauto_tvout.crc16</code>：<code>0x1634</code> |
| <code>stealth_noauto</code> | <code>flashme_v8a_lite_stealth_noauto_tvout.bin</code> | 仅终端显示 |
| <code>stealth</code> | <code>flashme_v8a_lite_stealth_tvout.bin</code> | 仅终端显示 |
| <code>normal</code> | <code>flashme_v8a_lite_tvout.bin</code> | 仅终端显示 |

## 运行机制

- 一级头 H 向 Boot ROM 提供 P1（ARM9）与 P2（ARM7）的固件位置和 RAM 暂存地址。
- P1 与 P2 同时开始运行。P2 读取早期按键和 Slot-2 标识：它可进入恢复路径，或读取 FlashMe 的 FH。
- FH 是存放在固件中的 FlashMe 二级头；其编码地址定位二级 FP1（ARM9）与 FP2（ARM7）镜像。
- FP1 处理 ARM9 的热/冷启动状态与后续跳转。FP2 选择保留任天堂或 FlashMe 路径、完成 ARM7 侧同步，再转交控制权。
- P3 是保留 ARM9 GUI/验证代码，P4 是 ARM7 无线代码，P5 为图形/数据；仅文档说明的位置被修改。

## 分析记录

- **TV-out 修改机制。** TV-out 专有代码只位于 FP2；其中内嵌了 V6 的保留 ARM7 P2。
  原 P2 的启动初始化在 <code>RetailP2RamAddress + 0x58E</code> 将 <code>0xFFFF</code>
  写入 <code>0x04001080</code>。这是 DS Lite 隐藏功能的写一次锁 <code>REG_REGCNT</code>：
  锁定后不能再读写其后的显示切换寄存器。TVout 以 Thumb 调用替换该写入，并将
  <code>+0x76C</code> 的载入常量改为 <code>0x4000</code>。辅助例程因此写入
  <code>0x04001090 = 1</code>（<code>REG_DISPCNT2</code> 单屏模式）及
  <code>0x040010A0 = 0x4000</code>（<code>REG_DISPSW</code> 的 TV 输出使能位）。
  也就是说，关键不是 IPS 本身，而是把任天堂 V6 原本的锁定操作改为启用隐藏 TV 输出。
  寄存器名称与位义可交叉参考 [melonDS 的 DS Lite 寄存器记录](https://melonds.kuribo64.net/board/thread.php?pid=5772)；
  本仓库的 V6 P2 原始控制流独立证实了锁定写入及其被替换的位置。
- <code>ndstvout-patch.ips</code> 仅作为来自
  [LNH-team / Lost-NDS-TV](https://github.com/LNH-team/Lost-NDS-TV/) 的存档字节参考，
  不是构建输入，也不用于推断上述运行机制。
- Start+Select 或 Slot-2 Game Code <code>BOOT</code> 进入修订后的早期路径；ARM7 通过邮箱要求 ARM9 执行冷启动准备。
- 若 <code>0x027FF80C + 0x0C</code> 为零，ARM7 以驻留 NDS 头中的 ARM9/ARM7 源、目标、大小和入口字段执行标准 <code>B7</code> 读取；非零则回退 Slot-2。
- 该状态字的语义尚未确认；<code>noauto</code> 将手动 FlashMe 选择改为 Select。
