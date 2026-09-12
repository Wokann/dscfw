
.create "build/p1.bin", 0
    .headersize PrimaryP1RamAddress
    .arm

    ldr r0, [p1_handoff_slot]
    bx r0
p1_handoff_slot:
    .dw PrimaryP1RamAddress
p1_primary_end:

    .if p1_primary_end > PrimaryP1StagingRegionEnd
        .error "FlashMe: primary P1 exceeds its staging page"
    .endif
.close
