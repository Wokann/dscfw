# FlashMe V7 New Phat 构建包

[English](README.md)

## 声明

本包仅包含 ARMIPS 源代码与 CRC 参考记录，不分发任天堂固件镜像或原始 FlashMe 镜像。

## 构建

将 <code>official_v3.bin</code> 放入 <code>flashme/</code> 根目录后，在本目录运行
<code>make</code>。
如需构建表中全部变体，运行 <code>make variants</code>。

## CRC-16/IBM

每次构建都会校验 <code>[0x000000, 0x3F800)</code> 范围。UTF-8
<code>*.crc16</code> 文件保存对应参考值。

| 变体 | 输出 | CRC 记录 | CRC-16 |
| --- | --- | --- | --- |
| <code>stealth</code> | <code>flashme_v7_new_phat_stealth.bin</code> | <code>flashme_v7_new_phat_stealth.crc16</code> | <code>0x0EE8</code> |
| <code>normal</code> | <code>flashme_v7_new_phat.bin</code> | <code>flashme_v7_new_phat.crc16</code> | <code>0x5445</code> |

## 运行机制

- 一级头 H 向 Boot ROM 提供 P1（ARM9）与 P2（ARM7）的固件位置和 RAM 暂存地址。
- P1 与 P2 同时开始运行。P2 读取早期按键和 Slot-2 标识：它可进入恢复路径，或读取 FlashMe 的 FH。
- FH 是存放在固件中的 FlashMe 二级头；其编码地址定位二级 FP1（ARM9）与 FP2（ARM7）镜像。
- FP1 处理 ARM9 的热/冷启动状态与后续跳转。FP2 选择保留任天堂或 FlashMe 路径、完成 ARM7 侧同步，再转交控制权。
- P3 是保留 ARM9 GUI/验证代码，P4 是 ARM7 无线代码，P5 为图形/数据；仅文档说明的位置被修改。
## 分析记录

- V7 New Phat 保留私有 DSLink/MK2/MK3 装载路径。
- 它还调整该路径周围的 SPI 响应处理。命令层差异已验证，但精确硬件目的及用户可见效果未解。
- 同样适用 V7 Old Phat 的私有协议兼容性提醒。