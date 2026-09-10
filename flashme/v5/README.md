# FlashMe V5 armips 补丁工作流

此目录以官方 NTR Firmware V3 为唯一固件输入，重建 FlashMe V5 的常规或 Stealth 镜像。两种变体共享同一套汇编源码，由 Makefile 向 armips 传入条件定义选择其二级引导路径。

流程不依赖原始 FlashMe 安装器或用于分析的 `temp2/`：FlashMe 的新增代码、头部改动和局部指令替换均已写入 `src/` 下的 armips 源文件。

## 目录结构

```text
official_v3.bin       官方 V3 输入固件
Makefile              构建入口
include/symbol.inc    共享定义
src/main.s            armips 入口，包含全部组件补丁
src/patch_h.s         主固件头 H
src/patch_p1.s ...    P1--P5
src/patch_fh.s        FlashMe 头 FH
src/patch_fp1.s ...   FP1、FP2
temp/                 从官方 V3 直接导出的明文 H、P1--P5
build/                armips 生成的明文 H、P1--P5、FH、FP1、FP2
flashme_v5.bin        常规版最终打包镜像
flashme_v5_stealth.bin Stealth 版最终打包镜像
```

`temp/` 和 `build/` 中只存放明文组件。压缩、P1/P2 加密、组件对齐、头部偏移及校验更新全部由最后的 `dsfwtool` 打包命令处理。V5 对 P3--P5 明确选择 `--p345-nearest-greedy`：它采用历史 FlashMe 所需的紧凑、最近距离、无延迟匹配策略，使固定在 `0x3F680` 的 FH 能与全部组件共存于 256 KiB 镜像。该选项不改变官方固件默认使用的逐字节还原 P345 策略。

## 前置文件

本目录需要：

- `official_v3.bin`：官方 NTR Firmware V3；
- `../armips.exe`：armips；
- `../dsfwtool.exe`：支持 `--p345-nearest-greedy` 的 dsfwtool。

默认布局已将两个工具放在 `v5` 的父目录。若官方固件位于其他位置，可在调用时覆写 `OFFICIAL_V3`，例如：

```bat
make OFFICIAL_V3=D:/firmware/official_v3.bin
```

## 构建

常规版：

```bat
make
```

Stealth 版：

```bat
make VARIANT=stealth
```

也可一次构建两个变体：

```bat
make variants
```

`Makefile` 依次执行：

1. 使用 `dsfwtool -x` 将官方 V3 导出为 `temp/` 内的解密、解压明文组件；
2. 使用 `armips` 执行 `src/main.s`，在 `build/` 生成所选 FlashMe V5 变体的明文组件；
3. 使用 `dsfwtool -c` 对 P1/P2 压缩并加密；对 P3--P5 使用紧凑 P345 模式、对 FP1/FP2 使用 P12 压缩；并在 `0x3F680` 写入 FH，生成根目录对应的 V5 镜像。

## 组件构造

- H、P1、P2、FH：由 armips 源码直接生成。
- FP1：`0x200` 字节 FlashMe ARM9 前缀，加上官方 P1。常规版有六处 Thumb 兼容性补丁；Stealth 版保留其中两处。
- FP2：`0x200` 字节 FlashMe ARM7 前缀，加上官方 P2。常规版保留服务路径的 IPC 时序；Stealth 版直接转入对应的保留 P2 路径。
- P3：以官方 P3 为基础进行三处局部 Thumb 补丁。
- P4、P5：直接保留官方 V3 的明文内容。

因此源码表达的是组件级结构和真正的修改点，而不是会把整体搬移误识别为改动的镜像逐字节差分。
