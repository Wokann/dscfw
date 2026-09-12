# FlashMe V8a Phat 重建工程

[English](README.md)

本 armips 工程以任天堂原始 <code>official_v3.bin</code> 为基底，重建 FlashMe
V8a Phat 的布局。已提取的 FlashMe 镜像只用作
验证参考，绝不作为构建输入。

> 四种变体为 normal、stealth、noauto 与 stealth_noauto。

## 输入与工具

- 将 <code>official_v3.bin</code> 放在 <code>flashme/</code> 根目录。
- 嵌套的 V7/V8 包使用 <code>../../tools/armips/armips.exe</code> 与
  <code>../../tools/dsfwtool/dsfwtool.exe</code>；其他相对路径以本包 <code>Makefile</code> 的定义为准。
- <code>temp/</code> 保存从任天堂原始输入导出的明文 H/P1–P5；<code>build/</code> 保存 armips
  生成的明文替换组件。

## 构建

~~~sh
make
~~~
~~~sh
make VARIANT=stealth
~~~
~~~sh
make VARIANT=noauto
~~~
~~~sh
make VARIANT=stealth-noauto
~~~
构建全部受支持变体：<code>make variants</code>。

最后的 <code>dsfwtool</code> 调用会重算组件元数据，执行所需压缩/加密，按 <code>Makefile</code>
指定的精确 ROM 偏移放置组件，将镜像填充到 256 KiB，并从任天堂原始输入保留
适用的设置区。

## 输出与校验

构建会先校验任天堂原始基底，之后为每个结果写出同名 UTF-8 CRC 记录，并将
FlashMe 的 CRC-16/IBM 范围 <code>[0x000000, 0x3F800)</code> 与已找回参考镜像的值比较。

| 变体 | 输出 | CRC 记录 | 参考 CRC-16 |
| --- | --- | --- | --- |
| <code>normal</code> | <code>flashme_v8a_phat.bin</code> | <code>flashme_v8a_phat.crc16</code> | <code>0xF482</code> |
| <code>stealth</code> | <code>flashme_v8a_phat_stealth.bin</code> | <code>flashme_v8a_phat_stealth.crc16</code> | <code>0x0828</code> |
| <code>noauto</code> | <code>flashme_v8a_phat_noauto.bin</code> | <code>flashme_v8a_phat_noauto.crc16</code> | <code>0x0708</code> |
| <code>stealth_noauto</code> | <code>flashme_v8a_phat_stealth_noauto.bin</code> | <code>flashme_v8a_phat_stealth_noauto.crc16</code> | <code>0x842F</code> |

<code>normal</code> 不带变体后缀；<code>stealth</code>、<code>noauto</code>、<code>stealth_noauto</code> 位于型号之后。
Makefile 中的 <code>stealth-noauto</code> 目标对应输出名里的 <code>stealth_noauto</code>。

## 重建模型

工程先通过 <code>dsfwtool</code> 导出解密、解压后的原始组件，再应用 <code>src/</code> 下的 armips
补丁，最后把 H/P1–P5/FH/FP1/FP2 打包回一份固件镜像。源码、生成组件布局及所有
变体专属地址均保持在本包内；ROM 放置规则以 <code>Makefile</code> 为准。
