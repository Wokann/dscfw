// P4 is a later retail component and is retained unchanged; it is outside the
// two-stage ARM9/ARM7 hand-off described in main.s.
// P4 是后续的零售组件，保持不变；它不属于 main.s 所述的两阶段 ARM9/ARM7 交接。
.create "build/p4.bin", 0
    .incbin "temp/p4.bin"
.close
