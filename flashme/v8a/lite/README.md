# FlashMe V8a Lite armips reconstruction

This project rebuilds the four FlashMe V8a Lite variants from a Nintendo DS
V6 retail firmware.  The only firmware build input is `official_v6.bin`; an
extracted FlashMe image is a verification reference, never a build input.

## Build

- Place the V6 retail firmware beside this file as `official_v6.bin`.
- `../../armips.exe` must be the armips assembler.
- `../../dsfwtool.exe` must support FlashMe components and P345
  `-comp -flashme` compression.

```sh
make VARIANT=normal
make VARIANT=stealth
make VARIANT=noauto
make VARIANT=stealth-noauto
make variants
```

`temp/` receives plaintext H and P1--P5 from V6.  armips writes plaintext
replacement components to `build/`; dsfwtool then updates component metadata,
compresses/encrypts applicable components, applies the historical V8a layout,
and preserves V6's settings area.

| Component | ROM offset |
| --- | ---: |
| P1 / P2 / P5 | 0x180 / 0x270 / 0x510 |
| P4 / P3 | 0x0F800 / 0x18610 |
| FP2 | 0x2A240 |
| FP1 normal / Stealth / NoAuto / Stealth-NoAuto | 0x328F8 / 0x328D8 / 0x328F0 / 0x328D0 |
| FH | 0x3F680 |

---

# FlashMe V8a Lite 的 armips 重建工程

本工程从 Nintendo DS V6 零售固件重建四种 FlashMe V8a Lite 变体。唯一的固件构建
输入为 `official_v6.bin`；导出的 FlashMe 镜像仅用于验证，绝不作为构建输入。

## 构建

- 将 V6 零售固件放在本文件同级目录，命名为 `official_v6.bin`。
- `../../armips.exe` 必须为 armips 汇编器。
- `../../dsfwtool.exe` 必须支持 FlashMe 组件及 P345 的
  `-comp -flashme` 压缩。

```sh
make VARIANT=normal
make VARIANT=stealth
make VARIANT=noauto
make VARIANT=stealth-noauto
make variants
```

`temp/` 保存从 V6 提取的 H 与 P1--P5 明文。armips 会将替换组件明文写入 `build/`；
随后 dsfwtool 更新组件元数据、对适用组件压缩/加密、应用历史 V8a 布局，并保留 V6 的
设置区。

| 组件 | ROM 偏移 |
| --- | ---: |
| P1 / P2 / P5 | 0x180 / 0x270 / 0x510 |
| P4 / P3 | 0x0F800 / 0x18610 |
| FP2 | 0x2A240 |
| FP1 常规 / Stealth / NoAuto / Stealth-NoAuto | 0x328F8 / 0x328D8 / 0x328F0 / 0x328D0 |
| FH | 0x3F680 |
