.create "build/p3.bin", 0
    .headersize RetailP3RamAddress
    .incbin "temp/p3.bin"

; NOP the Lite Logo gate; make the next two Lite P3 verifier routines return success. See after .close.
; 将 Lite Logo 闸门置为 NOP；令后两处 Lite P3 验证例程返回成功。详见 .close 后。
    .org NintendoLogoStateGate
    .thumb
; Patch 1: replace the retained Nintendo Logo decision with no operation.
; 补丁 1：将保留 Nintendo Logo 判断替换为空操作。
    nop

    .org RSA_verify
    .thumb
; Patch 2: make the first verifier report success before returning.
; 补丁 2：令第一处验证例程在返回前报告成功。
    mov r0, #1
    bx lr

    .org RSA_verify_with_SHA1
    .thumb
; Patch 3: make the second verifier report success before returning.
; 补丁 3：令第二处验证例程在返回前报告成功。
    mov r0, #1
    bx lr
.close

; Detailed analysis / 详细分析:
; 1. The first patched instruction is a NOP at the retained P3 Nintendo Logo decision point.
; 2. The second and third patched sites each load `r0 = 1` and return immediately, replacing their verifier bodies.
; 3. These changes affect this retained P3 GUI/verification path only. They should not be read as a general claim
;    that all NDS cartridge or network verification is disabled.
; 1. 第一处补丁是在保留 P3 的 Nintendo Logo 判断点写入 NOP。
; 2. 第二、三处补丁各自写入 `r0 = 1` 后立即返回，替换其验证例程主体。
; 3. 这些修改只影响该保留 P3 GUI/验证路径；不应将其理解为所有 NDS 卡带或网络验证均被关闭。
