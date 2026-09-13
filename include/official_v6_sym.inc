; Nintendo official_v6 source-firmware layout
.definelabel RetailP1RamAddress,                      0x02320000
.definelabel RetailP2RamAddress,                      0x037fa800
.definelabel RetailP3RamAddress,                      0x02358e00
.definelabel RetailP4RamAddress,                      0x02300200
.definelabel RetailP5RamAddress,                      0x023a4a80
; Analyst names; these are not recovered Nintendo symbols.  Boot* names are
; functional inferences; the CRC16 gate names are supported by dsofw analysis.
.definelabel BootStateDispatch,                        RetailP1RamAddress + 0x000002f8
.definelabel BootDisplayFade_1,                        RetailP1RamAddress + 0x0000089a
.definelabel BootDisplayFade_2,                        RetailP1RamAddress + 0x000008b6
.definelabel BootDisplayFade_3,                        RetailP1RamAddress + 0x000008ca
.definelabel P3P4Crc16Gate,                            RetailP1RamAddress + 0x00006d74
.definelabel P5Crc16Gate,                              RetailP1RamAddress + 0x00006de4
.definelabel NintendoLogoStateGate,                    RetailP3RamAddress + 0x00010198
.definelabel RSA_verify,                               RetailP3RamAddress + 0x00013eec
.definelabel RSA_verify_with_SHA1,                     RetailP3RamAddress + 0x000173dc
.definelabel TvoutDisplayControlLock,                  RetailP2RamAddress + 0x0000058e
.definelabel TvoutDisplaySwitchValue,                  RetailP2RamAddress + 0x0000076c
