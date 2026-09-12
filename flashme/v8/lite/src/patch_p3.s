
.create "build/p3.bin", 0
    .headersize RetailP3RamAddress
    .incbin "temp/p3.bin"

    .org RetailP3RamAddress + 0x10198
    .thumb
    nop

    .org RetailP3RamAddress + 0x13eec
    .thumb
    mov r0, #1
    bx lr

    .org RetailP3RamAddress + 0x173dc
    .thumb
    mov r0, #1
    bx lr
.close
