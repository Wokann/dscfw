
.create "build/p3.bin", 0
    .headersize RetailP3RamAddress
    .incbin "temp/p3.bin"

    .org RetailP3RamAddress + 0x1019c
    .thumb
    nop

    .org RetailP3RamAddress + 0x13ed0
    .thumb
    mov r0, #1
    bx lr

    .org RetailP3RamAddress + 0x173c0
    .thumb
    mov r0, #1
    bx lr
.close
