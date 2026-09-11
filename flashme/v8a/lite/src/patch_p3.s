// P3 retains V6 except for the V8a verification compatibility bypasses.
// P3 保留 V6，仅加入 V8a 验证兼容性绕过。
.create "build/p3.bin", 0
    .incbin "temp/p3.bin"
    .orga 0x10198
    .thumb
    nop
    .orga 0x13eec
    .thumb
    mov r0, #1
    bx lr
    .orga 0x173dc
    .thumb
    mov r0, #1
    bx lr
.close
