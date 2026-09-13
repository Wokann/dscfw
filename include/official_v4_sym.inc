; Nintendo official_v4 source-firmware layout
.definelabel RetailP1RamAddress,                      0x02320000
.definelabel RetailP2RamAddress,                      0x037fa800
.definelabel RetailP3RamAddress,                      0x02358dc0
.definelabel RetailP4RamAddress,                      0x02300200
.definelabel RetailP5RamAddress,                      0x023a4a00
; Analyst names; these are not recovered Nintendo symbols.  Boot* names are
; functional inferences; the CRC16 gate names are supported by dsofw analysis.
.definelabel BootStateDispatch,                        RetailP1RamAddress + 0x000002dc
.definelabel BootDisplayFade_1,                        RetailP1RamAddress + 0x0000089e
.definelabel BootDisplayFade_2,                        RetailP1RamAddress + 0x000008ba
.definelabel BootDisplayFade_3,                        RetailP1RamAddress + 0x000008ce
.definelabel P3P4Crc16Gate,                            RetailP1RamAddress + 0x00006dac
.definelabel P5Crc16Gate,                              RetailP1RamAddress + 0x00006e1c
.definelabel NintendoLogoStateGate,                    RetailP3RamAddress + 0x0001019c
.definelabel RSA_verify,                               RetailP3RamAddress + 0x00013eb8
.definelabel RSA_verify_with_SHA1,                     RetailP3RamAddress + 0x000173a8
