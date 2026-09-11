# FlashMe V8a Phat reconstruction

This armips project rebuilds all four FlashMe V8a Phat variants from a Nintendo DS V3 retail firmware. It unpacks the retail image into plaintext `temp/`, creates the altered plaintext components in `build/`, and asks `dsfwtool` to pack them. The extracted FlashMe template is only a verification reference and is never a build input.

```sh
make OFFICIAL_V3=/path/to/official_v3.bin VARIANT=normal
make OFFICIAL_V3=/path/to/official_v3.bin VARIANT=stealth
make OFFICIAL_V3=/path/to/official_v3.bin VARIANT=noauto
make OFFICIAL_V3=/path/to/official_v3.bin VARIANT=stealth-noauto
```

P1/P2 are the V8a Phat first-stage pair. FP1 contains the Phat ARM9 prefix followed by retained V3 P1; FP2 is the Phat ARM7 second-stage prefix followed by retained V3 P2. Every source file required by this package is contained below `phat/`; it has no source dependency on a Lite package. P3 supplies the signature/hash compatibility modifications; P4 and P5 remain retail.

## 中文说明

本 armips 工程会从 Nintendo DS V3 零售固件重建四种 FlashMe V8a Phat 变体。它先将零售镜像解包到明文 `temp/`，在 `build/` 创建已变更的明文组件，最后交由 `dsfwtool` 打包。导出的 FlashMe 模板仅作验证参考，绝不会作为构建输入。

`P1/P2` 是 V8a Phat 的一级程序对；`FP1` 由 Phat ARM9 代码和保留的 V3 P1 构成；`FP2` 由 Phat ARM7 二级前置代码和保留的 V3 P2 构成。本包所需全部源码均位于 `phat/` 下，不会在源码层面依赖 Lite 包。P3 包含签名/哈希兼容修改，P4/P5 保持零售内容。
