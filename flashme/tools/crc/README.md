# FlashMe CRC utility

<code>flashmecrc</code> is a small dependency-free C99 program used by the
FlashMe reconstruction Makefiles. Its source is retained so Linux and macOS
users can build a native executable; the Windows <code>flashmecrc.exe</code>
is built from the same source and may be checked in as a convenience binary.

Build it with:

~~~sh
make
~~~

The three supported modes are:

~~~text
flashmecrc crc32-official --image FILE --range-end N \
    --private-fill-start N --private-fill-end N --expected N --write FILE

flashmecrc crc16-flashme --image FILE --reference FILE --range-end N \
    --expected N --write FILE

flashmecrc crc16-record --image FILE --range-end N --write FILE
~~~

<code>crc32-official</code> calculates CRC-32/ISO-HDLC while virtually
filling the specified private range with <code>FF</code>; it never modifies
the source image. <code>crc16-flashme</code> verifies both a rebuilt image and
its released FlashMe reference with CRC-16/IBM. <code>crc16-record</code> is
used only when a historical reference does not exist, currently the inferred
V2 reconstruction.

---

# FlashMe CRC 工具

<code>flashmecrc</code> 是 FlashMe 重建 Makefile 使用的无依赖 C99 小工具。
保留源码以便 Linux 与 macOS 用户编译本机版本；Windows
<code>flashmecrc.exe</code> 由同一份源码构建，可作为方便使用的固化二进制
一并提交。

执行 <code>make</code> 即可编译。三种模式分别用于：按私有区虚拟填
<code>FF</code> 的任天堂固件 CRC-32、已发布 FlashMe 与重建镜像的 CRC-16
比对，以及没有历史镜像可比对时的单独记录（目前仅推定 V2）。工具不会修改
参与校验的固件镜像。
