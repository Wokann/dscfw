# FlashMe 源码维护记录

[English](CHANGELOG.md)

## 声明

本文件有意不保留历史功能分析或推断性的版本变更结论。源码树不分发任天堂固件或原始
FlashMe 镜像；FlashMe V2 没有构建包或 CRC 基准。

## 构建与 CRC 记录

提供 <code>official_v3.bin</code> 与 <code>official_v6.bin</code> 后，在
<code>flashme/</code> 根目录运行 <code>make</code>。输入校验使用 CRC-32/ISO-HDLC，
并将 <code>[0x2A, 0x180)</code> 虚拟填充为 <code>FF</code>；输出校验使用每个包
声明范围内的 CRC-16/IBM。当前构建与校验表见 [README.zh-cn.md](README.zh-cn.md)。