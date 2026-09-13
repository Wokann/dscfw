; Nintendo official_kor_v1 source-firmware layout
.definelabel RetailP1RamAddress,                      0x02320000
.definelabel RetailP2RamAddress,                      0x037fa800
.definelabel RetailP3RamAddress,                      0x02364b80
.definelabel RetailP4RamAddress,                      0x02300200
.definelabel RetailP5RamAddress,                      0x0237c4e0
; Analyst names; these are not recovered Nintendo symbols.  Boot* names are
; functional inferences; the CRC16 gate names follow the matching control flow.
.definelabel BootStateDispatch,                        RetailP1RamAddress + 0x00000358
.definelabel BootDisplayFade_1,                        RetailP1RamAddress + 0x000008f6
.definelabel BootDisplayFade_2,                        RetailP1RamAddress + 0x00000912
.definelabel BootDisplayFade_3,                        RetailP1RamAddress + 0x00000926
.definelabel P3P4Crc16Gate,                            RetailP1RamAddress + 0x00006e34
.definelabel P5Crc16Gate,                              RetailP1RamAddress + 0x00006f00
.definelabel NintendoLogoStateGate,                    RetailP3RamAddress + 0x000102b6
.definelabel RSA_verify,                               RetailP1RamAddress + 0x000098c4
.definelabel RSA_verify_with_SHA1,                     RetailP1RamAddress + 0x0000cdb4
.definelabel TvoutDisplayControlLock,                  RetailP2RamAddress + 0x000005d2
.definelabel TvoutDisplaySwitchValue,                  RetailP2RamAddress + 0x000007d4
