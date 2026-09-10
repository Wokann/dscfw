// Later verification-compatibility stage.  P3 is not part of the immediate
// P1/P2 -> FP1/FP2 ARM9/ARM7 hand-off; these component-relative Thumb changes
// allow the later retail code to accept the modified firmware contents.
// 后续验证兼容阶段。P3 不属于即时的 P1/P2 -> FP1/FP2 ARM9/ARM7 交接；这些相对于
// 组件的 Thumb 修改让稍后运行的零售代码能够接受已经改写的固件内容。
.create "build/p3.bin", 0
    .incbin "temp/p3.bin"

    // English: Retail P3 executes `beq +0x4` here after testing a helper
    // result.  That branch skips the following write of 0x0D to a state field
    // when r0 is zero.  Replacing it with NOP always performs the write.  This
    // is a forced state transition, not the RSA instruction sequence itself.
    // 中文：零售 P3 在这里测试辅助函数结果后执行 `beq +0x4`。当 r0 为零时，该
    // 跳转会越过后续向状态字段写入 0x0D 的操作。替换为 NOP 后会始终执行写入。
    // 这是强制状态转换，并非 RSA 指令序列本身。
    .orga 0x10198
    .thumb
    nop

    // English: Retail P3's function at +0x13ED0 is an RSA-1024/SHA-1 public
    // key verification path: it uses exponent 0x00010001, processes 0x80-byte
    // values, validates a PKCS#1 v1.5 01 FF..00 block, and requires a 20-byte
    // SHA-1 result.  `mov r0,#1; bx lr` returns success immediately and skips
    // all of that signature verification.
    // 中文：零售 P3 的 +0x13ED0 函数是 RSA-1024/SHA-1 公钥验证路径：它使用
    // 0x00010001 指数，处理 0x80 字节数值，验证 PKCS#1 v1.5 的 01 FF..00 块，
    // 并要求得到 20 字节 SHA-1 结果。`mov r0,#1; bx lr` 会立即返回成功，从而跳过
    // 整个签名验证过程。
    .orga 0x13eec
    .thumb
    mov r0, #1
    bx lr

    // English: Retail P3's function at +0x173C0 builds a SHA-1 digest from
    // fields in its input structure, then compares all 20 bytes with the
    // expected digest.  The original comparison result remains in r0 on return.
    // This replacement returns one unconditionally, bypassing that hash-equality
    // check as well.
    // 中文：零售 P3 的 +0x173C0 函数会根据输入结构中的字段构造 SHA-1 摘要，随后把
    // 全部 20 字节与预期摘要比较。原始比较结果会保留在返回时的 r0 中。此替换会无条件
    // 返回 1，因此也绕过该哈希一致性检查。
    .orga 0x173dc
    .thumb
    mov r0, #1
    bx lr
.close
