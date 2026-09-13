# FlashMe V3 Phat 构建包

[English](README.md)

## 声明

本包仅包含 ARMIPS 源代码与 CRC 参考记录，不分发任天堂固件镜像或原始 FlashMe 镜像。

## 构建

将 <code>official_v3.bin</code> 放入仓库根目录后，在本目录运行
<code>make</code>。

若需构建 FH 迁移测试版，运行 <code>make fix_fh</code>。它会生成
<code>flashme_v3_phat_fix_fh.bin</code>：FH 位于 V5 起使用的
<code>0x3F680</code>，P2 也会编译为读取同一地址。该布局有意不同于原版，
因此只输出 BIN 并显示其 CRC-16；既不生成 CRC 记录，也不与原始镜像的 CRC 参考值比对。

## CRC-16/IBM

原始布局构建会校验 <code>[0x000000, 0x3FDFE)</code> 范围。UTF-8
<code>*.crc16</code> 文件是固定的存档参考记录，构建不会创建或更新它。BIN 生成后若不匹配，
只会报告警告，不会令构建失败。

| 变体 | 输出 | CRC 记录 | CRC-16 |
| --- | --- | --- | --- |
| <code>normal</code> | <code>flashme_v3_phat.bin</code> | <code>flashme_v3_phat.crc16</code> | <code>0xB439</code> |

## 运行机制

- 一级头 H 向 Boot ROM 提供 P1（ARM9）与 P2（ARM7）的固件位置和 RAM 暂存地址。
- P1 与 P2 同时开始运行。P2 读取早期按键和 Slot-2 标识：它可进入恢复路径，或读取 FlashMe 的 FH。
- FH 是存放在固件中的 FlashMe 二级头；其编码地址定位二级 FP1（ARM9）与 FP2（ARM7）镜像。
- FP1 处理 ARM9 的热/冷启动状态与后续跳转。FP2 选择保留任天堂或 FlashMe 路径、完成 ARM7 侧同步，再转交控制权。
- P3 是保留 ARM9 GUI/验证代码，P4 是 ARM7 无线代码，P5 为图形/数据；仅文档说明的位置被修改。
## 分析记录

- V3 保留 V1 的一级选择器、P3 验证修改、保留组件 CRC 绕过和 FP2 PWM 渐变。
- 保留 P1 的 <code>+0x2DC/+0x89E/+0x8BA/+0x8CE</code> 四处 normal 专用修改改变健康提示控制流；它们独立于 FP2 渐变。
- 实机表现符合这一分离：V3 有渐变，但不显示健康提示。
