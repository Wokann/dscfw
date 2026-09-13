# FlashMe TV-out 镜像构建源码

[English](README.md)

## 声明

本源码树使用用户自行提供的任天堂固件输入构建 DS Lite TV-out FlashMe 镜像模板；
不跟踪或分发任天堂固件镜像及原始 FlashMe 镜像。目前仅提供 V8a Lite 构建包。

## 构建

将 <code>official_v6.bin</code> 放入 <code>dscfw</code> 仓库根目录后，使用：

~~~sh
make
~~~

即可构建全部 TV-out 包；也可使用 <code>make v8a-lite</code>，或进入
<code>v8a/lite</code> 目录运行 <code>make</code>。运行 <code>make variants</code>
可构建全部已记录变体。

## 任天堂输入 CRC-32/ISO-HDLC

解包前，构建会在计算中将私有字节范围 <code>[0x2A, 0x180)</code> 虚拟填充为
<code>FF</code>，再对 <code>[0x000000, 0x3F9B8)</code> 计算 CRC-32/ISO-HDLC；
不会修改源输入。预期值为 <code>0x594067E9</code>。

<code>dscfw</code> 仓库根目录的 <code>official_v6.crc32</code> 是固定比对记录，校验不会重写它。

## TV-out 输出 CRC-16/IBM

<code>noauto</code> 历史存档变体将 <code>[0x000000, 0x3F800)</code> 与固定
UTF-8 <code>*.crc16</code> 记录比较；BIN 生成后若不匹配，仅报告警告，不重写记录或令
构建失败。其余非官方变体只在终端显示当前 CRC-16/IBM 值。

| 包 | 型号 | 任天堂输入 | 输出变体 | CRC 范围 |
| --- | --- | --- | --- | --- |
| <code>v8a/lite</code> | Lite | <code>official_v6.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |

## 资料

DS Lite 专用显示寄存器资料的本地副本见
[v8a/lite/include/ds_lite_nitro2_registers.h](v8a/lite/include/ds_lite_nitro2_registers.h)。
文件头记录了 [melonDS 帖子 #5772](https://melonds.kuribo64.net/board/thread.php?pid=5772)、
发布者 Generic（RSDuck）以及帖中所述的 Gericom 来源。
