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

## 后续计划

后续会存放基于这些资料制作的个人 iQue 与韩国固件相关源码项目。更长远的目标是提供依赖
devkitPro 等自制软件开发工具、可从零编译的 Nintendo DS 自制软件模板工程，而非依赖
恢复出的固件二进制数据。
