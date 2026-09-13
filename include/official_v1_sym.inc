; Nintendo official_v1 source-firmware layout
.definelabel RetailP1RamAddress,                      0x02320000
.definelabel RetailP2RamAddress,                      0x037fa800
.definelabel RetailP3RamAddress,                      0x02354f10
.definelabel RetailP4RamAddress,                      0x02300200
.definelabel RetailP5RamAddress,                      0x02373d00
; Analyst names; these are not recovered Nintendo symbols.  Boot* names are
; functional inferences.  This revision predates the separate P3/P4 and P5
; CRC16 gates used by v3 and later, so those later names are intentionally absent.
.definelabel BootStateDispatch,                        RetailP1RamAddress + 0x000002dc
.definelabel BootDisplayFade_1,                        RetailP1RamAddress + 0x000008a2
.definelabel BootDisplayFade_2,                        RetailP1RamAddress + 0x000008be
.definelabel BootDisplayFade_3,                        RetailP1RamAddress + 0x000008d2
.definelabel FirmwareIntegrityGate_1,                  RetailP1RamAddress + 0x00006db4
.definelabel NintendoLogoStateGate,                    RetailP3RamAddress + 0x00010198
.definelabel RSA_verify,                               RetailP3RamAddress + 0x00013a34
.definelabel RSA_verify_with_SHA1,                     RetailP3RamAddress + 0x00016f48
