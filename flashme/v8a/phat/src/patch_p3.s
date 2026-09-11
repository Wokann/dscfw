// P3 retains V3 except for the V8a compatibility bypasses.
// P3 保留 V3，仅加入 V8a 兼容性绕过。
.create "build/p3.bin", 0
    .incbin "temp/p3.bin"
    // Force the state transition that retail P3 conditionally skips.
    // 强制执行零售 P3 原本可能跳过的状态转换。
    .orga 0x1019c
    .thumb
    nop
    // Return success from RSA-1024/SHA-1 verification.
    // 从 RSA-1024/SHA-1 验证中直接返回成功。
    .orga 0x13ed0
    .thumb
    mov r0, #1
    bx lr
    // Return success from the later SHA-1 equality check.
    // 从后续 SHA-1 一致性检查中直接返回成功。
    .orga 0x173c0
    .thumb
    mov r0, #1
    bx lr
.close
