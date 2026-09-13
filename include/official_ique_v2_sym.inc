; Nintendo official_ique_v2 source-firmware layout
.definelabel RetailP1RamAddress,                      0x02320000
.definelabel RetailP2RamAddress,                      0x037fa800
.definelabel RetailP3RamAddress,                      0x02364900
.definelabel RetailP4RamAddress,                      0x02300200
.definelabel RetailP5RamAddress,                      0x0237c240
; Analyst names; these are not recovered Nintendo symbols.  Boot* names are
; functional inferences; the CRC16 gate names follow the matching control flow.
.definelabel BootStateDispatch,                        RetailP1RamAddress + 0x00000334
.definelabel BootDisplayFade_1,                        RetailP1RamAddress + 0x000008d6
.definelabel BootDisplayFade_2,                        RetailP1RamAddress + 0x000008f2
.definelabel BootDisplayFade_3,                        RetailP1RamAddress + 0x00000906
.definelabel P3P4Crc16Gate,                            RetailP1RamAddress + 0x00006dec
.definelabel P5Crc16Gate,                              RetailP1RamAddress + 0x00006eb8
.definelabel NintendoLogoStateGate,                    RetailP3RamAddress + 0x000102b6
.definelabel RSA_verify,                               RetailP1RamAddress + 0x00009858
.definelabel RSA_verify_with_SHA1,                     RetailP1RamAddress + 0x0000cd48
.definelabel TvoutDisplayControlLock,                  RetailP2RamAddress + 0x000005d2
.definelabel TvoutDisplaySwitchValue,                  RetailP2RamAddress + 0x000007bc
