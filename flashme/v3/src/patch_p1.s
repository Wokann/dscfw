
.create "build/p1.bin", 0
    .headersize PrimaryP1RamAddress
    .arm
    str r0, [r12, r0, lsl #3]

    ldr r0, [p1_handoff_slot]
    bx r0
p1_handoff_slot:
    .dw PrimaryP1RamAddress + 4

    .dw 0x00000000
p1_primary_end:

    .if p1_primary_end > PrimaryP1StagingRegionEnd
        .error "FlashMe: primary P1 exceeds its staging page"
    .endif
.close
