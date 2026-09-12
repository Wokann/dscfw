; Nintendo official_v6 source-firmware layout
.definelabel SourceShiftAmounts,                      readu16("temp/h.bin", HeaderShiftAmountsOffset)
.definelabel RetailP1RamAddress,                      FirmwarePart1RamaddrEncodingBase - (readu16("temp/h.bin", HeaderPart1RamaddrOffset) << (2 + ((SourceShiftAmounts >> 3) & 7)))
.definelabel RetailP2RamAddress,                      FirmwarePart2RamaddrEncodingBase - (readu16("temp/h.bin", HeaderPart2RamaddrOffset) << (2 + ((SourceShiftAmounts >> 9) & 7)))
.definelabel RetailP3RamAddress,                      0x02358e00
