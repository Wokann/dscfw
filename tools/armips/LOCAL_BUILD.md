# Local Armips build

This directory contains the Armips executable used by the FlashMe
reconstruction projects. The unmodified upstream documentation is preserved
in [README.md](README.md).

Upstream project: [Kingcom/armips](https://github.com/Kingcom/armips)

The exact source used for this executable is the public
[`flashme-arm-immediate-encoding` branch of Wokann/armips](https://github.com/Wokann/armips/tree/flashme-arm-immediate-encoding)
(verified branch head: `98757e2fdc79a21a1aeb884d05f4312125fffd68`). It is a
branch of the Armips source tree rather than an unrecorded local-only patch.
To obtain the matching source:

~~~text
git clone --branch flashme-arm-immediate-encoding --single-branch https://github.com/Wokann/armips.git
~~~

Its FlashMe-specific addition is the command-line option:

~~~text
-armimmediate canonical
-armimmediate max-imm8
~~~

The reconstruction Makefiles use <code>-armimmediate max-imm8</code> so ARM
immediates use the historical encoding policy needed to reproduce the released
FlashMe instruction bytes. <code>canonical</code> remains available as the
ordinary policy. No FlashMe patch source depends on an unrecorded binary-only
change: the selected policy is explicit in every package Makefile.

---

# 本地 Armips 构建说明

本目录存放 FlashMe 重建工程使用的 Armips 可执行文件；未修改的上游原始说明
保留在 [README.md](README.md)。

上游项目：[Kingcom/armips](https://github.com/Kingcom/armips)

本可执行文件使用的确切源码位于公开的
[Wokann/armips `flashme-arm-immediate-encoding` 分支](https://github.com/Wokann/armips/tree/flashme-arm-immediate-encoding)
（已确认的分支头为 `98757e2fdc79a21a1aeb884d05f4312125fffd68`）。它是 Armips
源码树的分支，而不是未公开的本地补丁。获取对应源码可执行：

~~~text
git clone --branch flashme-arm-immediate-encoding --single-branch https://github.com/Wokann/armips.git
~~~

该分支针对 FlashMe 增加了以下命令行选项：

~~~text
-armimmediate canonical
-armimmediate max-imm8
~~~

各 FlashMe Makefile 显式使用 <code>-armimmediate max-imm8</code>，以使用
能够复现已发布 FlashMe 指令字节的 ARM 立即数编码策略；<code>canonical</code>
仍保留为普通策略。补丁源码没有依赖未记录的二进制专有行为，所选策略均在每个
子工程的 Makefile 中明确写出。
