// Later verification-compatibility stage.  P3 is not part of the immediate
// P1/P2 -> FP1/FP2 ARM9/ARM7 hand-off; these component-relative Thumb changes
// allow the later retail code to accept the modified firmware contents.
// 后续验证兼容阶段。P3 不属于即时的 P1/P2 -> FP1/FP2 ARM9/ARM7 交接；这些相对于
// 组件的 Thumb 修改让稍后运行的零售代码能够接受已经改写的固件内容。
.create "build/p3.bin", 0
    .headersize RetailP3RamAddress
    .incbin "temp/p3.bin"

    // English: In Nintendo's original P3, this is the final branch after a
    // 91-tick display-brightness sequence. The preceding helper fades the two
    // display targets over 15 ticks, holds them at zero through tick 75, then
    // restores them through tick 90. Once it completes and the caller's
    // +0xE60 field is nonzero, original P3 queries an external status routine.
    // Its `beq` leaves the state unchanged when that query returns zero.
    // Replacing only that branch with NOP forces state +0xE48 to 0x0D after the
    // two preceding conditions are met. This is a post-fade state transition,
    // separate from the signature-verification patches below.
    // 中文：在任天堂原始 P3 中，这是一个 91 个时钟周期显示亮度序列结束后的最后
    // 分支。此前的帮助例程会在前 15 个周期渐变两个显示目标，在第 75 周期前维持为零，
    // 再在第 90 周期前恢复亮度。它完成且调用者的 +0xE60 字段非零后，原始 P3 会查询
    // 一个外部状态例程；原来的 `beq` 会在该查询返回零时不改变状态。这里只替换这条
    // 分支为 NOP，因此在前两项条件满足后总会把 +0xE48 状态写为 0x0D。这是淡入淡出
    // 后的状态转换，与下方的签名验证补丁相互独立。
    .org RetailP3RamAddress + 0x10198
    .thumb
    nop

    // English: This Nintendo original P3 routine is an RSA-1024/SHA-1 public
    // key verification path. It uses exponent 0x00010001, operates on two
    // 0x80-byte inputs, and returns success only after the recovered block
    // yields a parsed 20-byte SHA-1 digest. `mov r0,#1; bx lr` returns success
    // immediately, bypassing the public-key verification path.
    // 中文：这段任天堂原始 P3 例程是 RSA-1024/SHA-1 公钥验证路径。它使用
    // 0x00010001 指数，处理两个 0x80 字节输入，并且只会在恢复出的数据块成功解析为
    // 20 字节 SHA-1 摘要后返回成功。`mov r0,#1; bx lr` 会立即返回成功，从而绕过
    // 整条公钥验证路径。
    .org RetailP3RamAddress + 0x13eec
    .thumb
    mov r0, #1
    bx lr

    // English: This Nintendo original P3 routine builds a compound 20-byte
    // SHA-1 digest from a fixed region and fields described by its input
    // structure, then calls a 20-byte equality helper against the expected
    // digest. The helper's boolean result remains in r0 at return. This
    // replacement returns one unconditionally and bypasses that digest check.
    // 中文：这段任天堂原始 P3 例程会根据固定区域及输入结构所描述的字段构造一个复合
    // 的 20 字节 SHA-1 摘要，随后调用 20 字节相等性帮助例程，与预期摘要比较。帮助
    // 例程的布尔结果会在返回时保留于 r0。此替换无条件返回 1，从而绕过该摘要检查。
    .org RetailP3RamAddress + 0x173dc
    .thumb
    mov r0, #1
    bx lr
.close
