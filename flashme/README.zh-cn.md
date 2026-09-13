# FlashMe 镜像构建源码

[English](README.md)

## 声明

本源码树使用用户自行提供的任天堂固件输入构建 FlashMe 镜像模板；不跟踪或分发任天堂
固件镜像及原始 FlashMe 镜像。由于缺少经过验证的镜像或可靠技术资料，FlashMe V2
暂不提供。

## 构建

将 <code>official_v3.bin</code> 与 <code>official_v6.bin</code> 放入仓库根目录后，使用：

~~~sh
make
~~~

即可构建全部可用包。可使用 <code>make v1</code>、<code>make v8a-lite</code> 等顶层
目标构建单一包；也可进入包目录运行 <code>make</code>。具有多个已记录输出的包支持
<code>make variants</code>。

## 任天堂输入 CRC-32/ISO-HDLC

解包前，构建会在计算中将私有字节范围 <code>[0x2A, 0x180)</code> 虚拟填充为
<code>FF</code>，再对下列左闭右开范围计算 CRC-32/ISO-HDLC；不会修改源输入。

| 输入 | CRC 范围 | 预期 CRC-32 |
| --- | --- | --- |
| <code>official_v3.bin</code> | <code>[0x000000, 0x3F6F8)</code> | <code>0x96DF1D27</code> |
| <code>official_v6.bin</code> | <code>[0x000000, 0x3F9B8)</code> | <code>0x594067E9</code> |

根目录的 <code>official_v3.crc32</code> 与 <code>official_v6.crc32</code>
是固定比对记录，校验不会重写它们。

## FlashMe 输出 CRC-16/IBM

历史镜像复现包的 Makefile 会将表中左闭右开范围与其固定 UTF-8 <code>*.crc16</code>
记录读取的值比较。BIN 生成后若不匹配，只会报告警告，不会重写记录或令构建失败。

| 包 | 型号 | 任天堂输入 | 输出变体 | CRC 范围 |
| --- | --- | --- | --- | --- |
| <code>v1</code> | Phat | <code>official_v3.bin</code> | <code>normal</code> | <code>0x3FDFE</code> |
| <code>v3</code> | Phat | <code>official_v3.bin</code> | <code>normal</code> | <code>0x3FDFE</code> |
| <code>v4</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3FDFE</code> |
| <code>v5</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v6</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v7_old/phat</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v7_old/lite</code> | Lite | <code>official_v6.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v7_new/phat</code> | Phat | <code>official_v3.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v7_new/lite</code> | Lite | <code>official_v6.bin</code> | <code>stealth, normal</code> | <code>0x3F800</code> |
| <code>v8/phat</code> | Phat | <code>official_v3.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |
| <code>v8/lite</code> | Lite | <code>official_v6.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |
| <code>v8a/phat</code> | Phat | <code>official_v3.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |
| <code>v8a/lite</code> | Lite | <code>official_v6.bin</code> | <code>noauto, stealth_noauto, stealth, normal</code> | <code>0x3F800</code> |
