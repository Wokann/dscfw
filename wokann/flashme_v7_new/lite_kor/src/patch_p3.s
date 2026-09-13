; Retained Korean V1 P3: only bypass the Nintendo Logo state gate.
.create "build/p3.bin", 0
    .headersize RetailP3RamAddress
    .incbin "temp/p3.bin"
    .org NintendoLogoStateGate
    .thumb
    nop
.close
