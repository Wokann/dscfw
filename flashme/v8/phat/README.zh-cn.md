# FlashMe V8 Phat 构建包

[English](README.md)

## 声明

本包仅包含 ARMIPS 源代码与 CRC 参考记录，不分发任天堂固件镜像或原始 FlashMe 镜像。

## 构建

将 <code>official_v3.bin</code> 放入仓库根目录后，在本目录运行
<code>make</code>。
如需构建表中全部变体，运行 <code>make variants</code>。

## CRC-16/IBM

每次构建会将 <code>[0x000000, 0x3F800)</code> 与其 UTF-8
<code>*.crc16</code> 记录读取出的值比较。记录固定且不会重写；BIN 生成后若不匹配，
只报告警告，不会令构建失败。

| 变体 | 输出 | CRC 记录 | CRC-16 |
| --- | --- | --- | --- |
| <code>noauto</code> | <code>flashme_v8_phat_noauto.bin</code> | <code>flashme_v8_phat_noauto.crc16</code> | <code>0xE2A5</code> |
| <code>stealth_noauto</code> | <code>flashme_v8_phat_stealth_noauto.bin</code> | <code>flashme_v8_phat_stealth_noauto.crc16</code> | <code>0x9909</code> |
| <code>stealth</code> | <code>flashme_v8_phat_stealth.bin</code> | <code>flashme_v8_phat_stealth.crc16</code> | <code>0x58DF</code> |
| <code>normal</code> | <code>flashme_v8_phat.bin</code> | <code>flashme_v8_phat.crc16</code> | <code>0x5753</code> |

## 运行机制

- 一级头 H 向 Boot ROM 提供 P1（ARM9）与 P2（ARM7）的固件位置和 RAM 暂存地址。
- P1 与 P2 同时开始运行。P2 读取早期按键和 Slot-2 标识：它可进入恢复路径，或读取 FlashMe 的 FH。
- FH 是存放在固件中的 FlashMe 二级头；其编码地址定位二级 FP1（ARM9）与 FP2（ARM7）镜像。
- FP1 处理 ARM9 的热/冷启动状态与后续跳转。FP2 选择保留任天堂或 FlashMe 路径、完成 ARM7 侧同步，再转交控制权。
- P3 是保留 ARM9 GUI/验证代码，P4 是 ARM7 无线代码，P5 为图形/数据；仅文档说明的位置被修改。
## 分析记录

- V8 删除选择器对 V7 自动私有 DSLink/MK2/MK3 探测的调用。<code>fp2_aux_*</code> 辅助例程仍在，但选择器无法到达。
- 因此 normal/stealth 不再自动发送私有 Slot-1 序列；<code>noauto</code>/<code>stealth_noauto</code> 要求手动 A+B+X+Y 选择。
- Phat 保留既有的 normal 渐变策略。
