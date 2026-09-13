# FlashMe CRC utility

<code>flashmecrc</code> is a small dependency-free C99 program used by the
FlashMe reconstruction Makefiles. Its source is retained so Linux and macOS
users can build a native executable; the Windows <code>flashmecrc.exe</code>
is built from the same source and may be checked in as a convenience binary.

Build it with:

~~~sh
make
~~~

The four supported modes are:

~~~text
flashmecrc crc32-official --image FILE --range-end N \
    --private-fill-start N --private-fill-end N --expected N [--write FILE]

flashmecrc crc16-flashme --image FILE --reference FILE --range-end N \
    --expected N [--write FILE]

flashmecrc crc16-check --image FILE --range-end N --expected N

flashmecrc crc16-record --image FILE --range-end N [--write FILE]
~~~

<code>crc32-official</code> calculates CRC-32/ISO-HDLC while virtually
filling the specified private range with <code>FF</code>. <code>crc16-flashme</code>
optionally compares a rebuilt image and a supplied reference. The reconstruction
Makefiles use <code>crc16-check</code> to compare a rebuilt image with the fixed
value read from its checked-in record; they never write a record. A mismatch is
reported as a non-fatal warning after the output image has been created. Without
<code>--write</code>, <code>crc16-record</code> only prints the current value.

The tool accepts any image length; every supplied CRC or virtual-fill range must
remain within that image.

---

# FlashMe CRC 工具

<code>flashmecrc</code> 是 FlashMe 重建 Makefile 使用的无依赖 C99 小工具。
保留源码以便 Linux 与 macOS 用户编译本机版本；Windows
<code>flashmecrc.exe</code> 由同一份源码构建，可作为方便使用的固化二进制
一并提交。

执行 <code>make</code> 即可编译。四种模式分别用于：按私有区虚拟填
<code>FF</code> 的任天堂固件 CRC-32、可选地比对给定参考镜像的 CRC-16、按固定
期望值校验 CRC-16，以及单独输出 CRC-16。重建 Makefile 使用
<code>crc16-check</code> 读取仓库内固定记录文件的值，不会写入记录；省略
<code>--write</code> 时，<code>crc16-record</code> 只显示当前值。记录值不匹配仅在
输出镜像生成后报告警告，不会使构建失败。

工具接受任意长度的镜像；指定的 CRC 或虚拟填充范围都必须落在该镜像内。
