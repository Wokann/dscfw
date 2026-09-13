; Nintendo official_ique_v1 source-firmware layout
.definelabel RetailP1RamAddress,                      0x02320000
.definelabel RetailP2RamAddress,                      0x037fa800
.definelabel RetailP3RamAddress,                      0x02364b20
.definelabel RetailP4RamAddress,                      0x02300200
.definelabel RetailP5RamAddress,                      0x0237c460
; Analyst names; these are not recovered Nintendo symbols.  Boot* names are
; functional inferences; the CRC16 gate names follow the matching control flow.
.definelabel BootStateDispatch,                        RetailP1RamAddress + 0x000002dc
.definelabel BootDisplayFade_1,                        RetailP1RamAddress + 0x0000089e
.definelabel BootDisplayFade_2,                        RetailP1RamAddress + 0x000008ba
.definelabel BootDisplayFade_3,                        RetailP1RamAddress + 0x000008ce
.definelabel P3P4Crc16Gate,                            RetailP1RamAddress + 0x00006dc0
.definelabel P5Crc16Gate,                              RetailP1RamAddress + 0x00006e8c
.definelabel NintendoLogoStateGate,                    RetailP3RamAddress + 0x000102be
.definelabel RSA_verify,                               RetailP1RamAddress + 0x00009854
.definelabel RSA_verify_with_SHA1,                     RetailP1RamAddress + 0x0000cd44
