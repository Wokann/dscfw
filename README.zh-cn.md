# Nintendo DS 自制固件源码

[English](README.md)

## 项目说明

`dscfw` 是 Nintendo DS 自制固件源码仓库，不包含任何任天堂官方固件镜像或其他原始
二进制镜像数据。

本仓库目前保存 Loopy 的 FlashMe，以及 Lost Nintendo History 的 DS Lite TV-out
固件修改的复现重构源码。它们是历史固件的重构项目，不是任天堂官方固件发布版。

## 构建历史复现版本

请自行准备任天堂官方固件，并在 `dscfw` 仓库根目录中命名为
`official_v3.bin` 与 `official_v6.bin`。随后进入对应的 `flashme` 或 `tvout`
目录运行 `make`，即可构建其中已记录的变体。

构建会通过固定的归一化 CRC-32 记录校验所提供的基础固件。具有历史参考 CRC 记录的
FlashMe 与 TV-out 变体随后会报告生成结果是否与当年发布固件的有效字节一致。主机私有的
Wi-Fi 校准、MAC 地址、接入点与用户设置数据不会存储，也不视为跨主机共享的镜像数据；
因此不宣称不同主机之间的原始完整镜像逐字节一致。

可用构建包与具体规则请参阅 [flashme/README.zh-cn.md](flashme/README.zh-cn.md) 和
[tvout/README.zh-cn.md](tvout/README.zh-cn.md)。

## 地区构建与后续计划

基于 iQue 与韩国固件的 FlashMe 移植现已位于 [`wokann/`](wokann/)：

- [`wokann/flashme_v7_new/`](wokann/flashme_v7_new/)：iQue V1 Phat，以及
  iQue V2 Lite、韩国 V1 Lite 的 V7 New 构建；
- [`wokann/flashme_v8a/`](wokann/flashme_v8a/)：iQue V1 Phat，以及 iQue V2
  Lite、韩国 V1 Lite 的 V8a FlashMe 构建；
- [`wokann/tvout_v8a/`](wokann/tvout_v8a/)：iQue V2 Lite 与韩国 V1 Lite 的
  V8a TV-out 构建。

其余长期目标是提供依赖 devkitPro 等自制软件开发工具、可从零编译的 Nintendo DS
自制软件模板工程，而非依赖恢复出的固件二进制数据。
