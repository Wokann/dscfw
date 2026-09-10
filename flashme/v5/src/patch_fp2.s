// Stage 2 ARM7 half.  Primary P2 has already loaded this FH-described image;
// this prefix runs in parallel with FP1 on ARM9 and is the producer of FP1's
// IPC phase.  The first 0x200 bytes are new code, followed by retained retail
// P2 at its original runtime address.  See main.s for the complete two-CPU map.
// 第二阶段的 ARM7 一半。一级 P2 已经加载了这个由 FH 描述的镜像；本前置代码会与
// ARM9 上的 FP1 并行运行，并且是 FP1 所见 IPC 阶段的发布者。开头 0x200 字节是
// 新代码，之后是仍处于原始运行地址的零售 P2。完整双 CPU 时序请参见 main.s。
.create "build/fp2.bin", 0
    .headersize FlashMeFp2RamAddress
    .area FlashMePrefixBytes, 0x00
    .arm
    ldr r0, =REG_POWERCNT
    mov r1, #1
    strh r1, [r0]
    // mov r1, #0x3000, retaining the historical ARM immediate rotation.
    // mov r1, #0x3000，保留历史 ARM 立即数旋转编码。
    .dw 0xe3a01dc0
    swi SwiArm7SoundBiasImmediate
    ldr r10, =REG_KEYINPUT
    ldrh r0, [r10]
    // KEYINPUT is active-low: Z means Select is physically pressed, so this
    // first test takes the service route before the A/B/X/Y combination check.
    // KEYINPUT 为低有效：Z 表示 Select 物理上已按下，因此第一个判断会在检查
    // A/B/X/Y 组合前优先选择服务路径。
    tst r0, #KEY_SELECT
    beq fp2_service_boot
    // Z means both A and B are pressed because both masked bits are low.
    // Z 表示 A 与 B 均已按下，因为两个被屏蔽的位均为低。
    ands r0, r0, #(KEY_A | KEY_B)
    bne fp2_check_boot_state
    ldrh r0, [r10, #(REG_KEYXY - REG_KEYINPUT)]
    // REG_KEYXY is also active-low: Z means both X and Y are pressed.
    // REG_KEYXY 同样为低有效：Z 表示 X 与 Y 均已按下。
    ands r0, r0, #(KEYXY_X | KEYXY_Y)
    beq fp2_flash_boot

fp2_check_boot_state:
    // This is deliberately not a 16-byte string comparison.  It selects the
    // flash route when Slot-2 title[12..15] is "PASS", or when title[0..7]
    // is "DSBooter".  The compact V5 table contains only the two tested
    // words and the "PASS" word; it has no stored trailing "FLSH" word.
    // 这里刻意不是 16 字节字符串比较。当 Slot-2 标题的 [12..15] 为 "PASS"，
    // 或 [0..7] 为 "DSBooter" 时，会选择 flash 路径。紧凑的 V5 表只含两个
    // 被测试的字与 "PASS" 字，不再保存结尾的 "FLSH" 字。
    adr r0, fp2_boot_state
    ldmia r0, {r1-r4}
    ldmia r1, {r6-r9}
    // title[12..15] == "PASS".
    // title[12..15] == "PASS"。
    cmp r9, r4
    beq fp2_flash_boot
    // title[0..7] == "DSBooter".
    // title[0..7] == "DSBooter"。
    cmp r6, r2
    bne fp2_service_boot
    cmp r7, r3
    beq fp2_flash_boot

fp2_service_boot:
    // Publish ARM9-visible phase 0xB.  Normal V5 performs the inherited
    // service timing before D; Stealth directly enters retained P2.
    // 发布 ARM9 可见的阶段 0xB。常规 V5 会在 D 之前执行继承的服务时序；
    // Stealth 则直接进入保留 P2。
    // mov r0, #0x0b00, historical immediate encoding.
    // mov r0, #0x0b00，使用历史立即数编码。
    .dw 0xe3a00eb0
    strh r0, [r10, #0x50]

    .if BuildStealth
    ldr lr, =Arm9ReturnSlotFp2
    ldr lr, [lr]
    b fp2_retail
    .else
    // The V5 source uses the following exact non-canonical immediate forms.
    // V5 源码使用下列精确的非规范立即数形式。
    .dw 0xe3a05d40 // mov r5, #0x00001000
    .dw 0xe3a06b80 // mov r6, #0x00020000
    .dw 0xe3a07d60 // mov r7, #0x00001800

fp2_service_loop:
    mov r0, r5
    mov r4, #1
    bl fp2_ipc_call
    sub r0, r6, r5
    mov r4, #0x0d
    bl fp2_ipc_call
    add r5, r5, r7
    cmp r5, r6
    bmi fp2_service_loop
    .dw 0xe3a00ed0 // mov r0, #0x00000d00
    strh r0, [r10, #0x50]
    ldr lr, =Arm9ReturnSlotFp2
    ldr lr, [lr]
    b fp2_retail

fp2_ipc_call:
    stmdb sp!, {lr}
    swi SwiArm7WaitByLoopImmediate
    mov r0, #0
    mov r1, #0
    mov r2, #1
    bl fp2_ipc_send
    mov r0, #0
    mov r1, r4
    mov r2, #0
    bl fp2_ipc_send
    ldmia sp!, {pc}
    .endif

    .orga Fp2BootStateOffset
fp2_boot_state:
    .dw GbaRomTitleAddress
fp2_boot_signature:
    .ascii "DSBooterPASS"

fp2_flash_boot:
    // Publish ARM9-visible phase 0xC: FP1 will begin its cold preparation.
    // 发布 ARM9 可见的阶段 0xC：FP1 将开始冷启动准备。
    .dw 0xe3a00ec0 // mov r0, #0x00000c00
    strh r0, [r10, #0x50]
    ldr r0, =FlashMeFirmwareBytes
    ldr r4, =FlashMeHeaderRamAddress
    mov r1, r4
    .dw 0xe3a02f60 // mov r2, #0x00000180
    bl fp2_copy
    ldrh r1, [r4, #0x70]
    .dw 0xe2840f40 // add r0, r4, #0x00000100
    ldrh r2, [r0, #0x70]
    cmp r2, r1
    mov r1, r4
    mov r2, #0x20
    swihi SwiArm7CpuFastSetImmediate
    mov r0, #0
    mov r2, #0x2c
    ldr r1, =REG_DMA0SAD

fp2_clear_dma_range:
    str r0, [r1, r2]
    subs r2, r2, #4
    bpl fp2_clear_dma_range
    // V5 writes the two observed SPI command/data pairs after clearing the
    // header work range.  This replaces the earlier BIOS boot-return call.
    // V5 会在清除头工作区后写入两组已观察到的 SPI 命令/数据；它取代了早期的
    // BIOS boot-return 调用。
    mov r0, #0x00008a00
    mov r1, #0x00000084
    bl fp2_spi_write
    mov r0, #0x00008200
    mov r1, #0
    bl fp2_spi_write
    .dw 0xe3a01ed0 // mov r1, #0x00000d00

fp2_wait_d:
    strh r1, [r10, #0x50]
    ldrh r0, [r10, #0x50]
    and r0, r0, #0x0f
    cmp r0, #0x0d
    bne fp2_wait_d
    ldr r12, =Arm7ReturnEntry
    bx r12

fp2_spi_write:
    ldr r3, =REG_SPICNT

fp2_spi_wait:
    ldrh r2, [r3]
    tst r2, #0x80
    bne fp2_spi_wait
    strh r0, [r3]
    strh r1, [r3, #2]
    bx lr

fp2_copy:
    ldr r3, =BiosCopyRoutine
    bx r3

fp2_ipc_send:
    ldr r3, =BiosIpcSendRoutine
    bx r3

    .pool
    .endarea

fp2_retail:
    // This .incbin begins at output +0x200, so fp2_retail is exactly the retail
    // P2 entry address.  The retained body can keep all of its original address
    // assumptions; the prefix was added before it rather than relocating it.
    // 此 .incbin 从输出 +0x200 开始，因此 fp2_retail 恰好就是零售 P2 的入口地址。
    // 保留的主体可以继续使用全部原有地址假设；前置代码加在它之前，而没有搬移它。
    .incbin "temp/p2.bin"
fp2_retail_end:
    // Reject a source whose retained ARM7 body would reach the primary P2 window.
    // 拒绝保留 ARM7 主体会延伸至一级 P2 窗口的源镜像。
    .if fp2_retail_end > PrimaryP2RamAddress
        .error "FlashMe: FP2 overlaps the primary P2 staging window"
    .endif
.close

// =============================================================================
// C flow model (English)
// =============================================================================
// This is one comment-only C representation of the secondary ARM7 prefix.  It
// shows the observed low-active key tests, partial Slot-2 title tests, IPC
// phase publication, and the two non-returning transfers.  The raw BIOS calls
// remain named operations because their original register ABI is preserved by
// the assembly above.
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
// 这是二级 ARM7 前置代码的一份仅作注释的 C 表达。它展示已观察到的低有效按键判断、
// 部分 Slot-2 标题判断、IPC 阶段发布和两处不返回的交接。原始 BIOS 调用仍以命名操作
// 表示，因为上方汇编会保留其原始寄存器 ABI。
//
// typedef struct {
//     uintptr_t fp2Ram;
//     size_t prefixBytes;
//     uintptr_t arm9ReturnSlotFp2;
//     uintptr_t arm7ReturnEntry;
//     const void *flashImageEnd;
//     void *flashHeaderWork;
// } FlashMeFp2Layout;
//
// static const u8 Slot2BootSignature[12] = {
//     'D','S','B','o','o','t','e','r', 'P','A','S','S',
// };
//
// static bool SelectFlashRoute(void)
// {
//     const u16 keys = REG_KEYINPUT;
//
//     // English: All tested keypad bits are low when the physical key is pressed.
//     // 中文：所有被测试的按键位在物理按下时均为低电平。
//     if ((keys & KEY_SELECT) == 0)
//         return false;
//     if ((keys & (KEY_A | KEY_B)) == 0 &&
//         (REG_KEYXY & ((1u << 0) | (1u << 1))) == 0)
//         return true;
//
//     const u8 *const title = (const u8 *)GBAROM + 0xa0;
//     // English: This is OR logic, not a NUL-terminated string comparison.
//     // 中文：这是 OR 逻辑，而不是 NUL 结尾字符串比较。
//     return memcmp(title, Slot2BootSignature, 8) == 0 ||
//            memcmp(title + 12, Slot2BootSignature + 8, 4) == 0;
// }
//
// static __attribute__((noreturn)) void SecondaryFp2(
//     const FlashMeFp2Layout *layout)
// {
//     REG_POWERCNT = 1;
//     Arm7SoundBiasSwi((u32)(uintptr_t)&REG_POWERCNT, 0x3000);
//
//     if (!SelectFlashRoute()) {
//         REG_IPC_SYNC = 0x0b00;
//         if (!BuildStealth) {
//             // English: Normal V5 completes its inherited timing/IPC sequence.
//             // 中文：常规 V5 会完成继承的时序/IPC 序列。
//             for (u32 delay = 0x1000; delay < 0x20000; delay += 0x1800) {
//                 Arm7IpcCall(delay, 1);
//                 Arm7IpcCall(0x20000 - delay, 0x0d);
//             }
//             REG_IPC_SYNC = 0x0d00;
//         }
//         Arm7TailJumpWithLink(layout->fp2Ram + layout->prefixBytes,
//                              *(volatile u32 *)layout->arm9ReturnSlotFp2);
//     }
//
//     // English: Publish C, select the newest settings slot, and prepare D.
//     // 中文：发布 C，选择最新的设置槽，并准备 D。
//     REG_IPC_SYNC = 0x0c00;
//     Arm7BiosCopy(layout->flashImageEnd, layout->flashHeaderWork, 0x180);
//     volatile u8 *const header = layout->flashHeaderWork;
//     if (Read16(header + 0x170) > Read16(header + 0x070))
//         FastCopy(header + 0x100, header, 0x20);
//     for (int offset = 0x2c; offset >= 0; offset -= 4)
//         *(volatile u32 *)(header + offset) = 0;
//     SpiWrite(0x8a00, 0x0084);
//     SpiWrite(0x8200, 0x0000);
//
//     do REG_IPC_SYNC = 0x0d00; while ((REG_IPC_SYNC & 0x000f) != 0x000d);
//     Arm7TailJump(layout->arm7ReturnEntry);
// }

// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// FP2 is the policy producer for the second stage.  It starts beside FP1 and
// samples the raw active-low key registers exactly once before publishing an
// IPC phase.  Select chooses the service route; simultaneous A+B+X+Y chooses
// the cold route; otherwise the Slot-2 predicate accepts either "DSBooter" at
// title bytes 0..7 or "PASS" at bytes 12..15.  The latter is intentionally an
// OR of two partial comparisons, not a comparison against the whole 16-byte
// table.
//
// The service route publishes B.  Normal V5 then performs its inherited timing
// and IPC sequence, publishes D, and enters retained P2 with the ARM9 return
// link expected by that continuation.  Stealth instead enters retained P2
// immediately after B, matching FP1's abbreviated Stealth B route.  The cold
// route publishes C, copies the two user-settings slots at the image tail,
// selects the newer slot by its version field, clears the DMA/control register
// range beginning at REG_DMA0SAD,
// writes the two observed SPI command/data pairs, then repeatedly publishes D
// until the rendezvous is visible before transferring to the ARM7 return entry.
//
// This makes FP2 the single source of second-stage policy and IPC ordering,
// while FP1 is responsible for the ARM9-side response.  FP2 retains the retail
// P2 body at its original runtime entry for the warm route, just as FP1 retains
// retail P1; neither retained body is relocated by adding the prefix.
//
// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// FP2 是第二阶段的策略生产者。它与 FP1 同时开始，在发布 IPC 阶段前只采样一次原始
// 低有效按键寄存器。Select 选择服务路径；同时按下 A+B+X+Y 选择冷启动路径；其他情况
// 则由 Slot-2 谓词决定，接受标题字节 [0..7] 的 "DSBooter" 或 [12..15] 的 "PASS"。
// 后者有意是两个部分比较的 OR，而不是与完整 16 字节表进行比较。
//
// 服务路径会发布 B。常规 V5 随后执行继承的时序与 IPC 序列、发布 D，并携带该续接所
// 期望的 ARM9 返回链接进入保留 P2；Stealth 则在发布 B 后立即进入保留 P2，与 FP1 的
// 简化 Stealth B 路径相配合。冷启动路径则发布 C，从镜像尾部复制两个用户设置槽，通过
// 版本字段选择较新的槽，清除从 REG_DMA0SAD 开始的 DMA/控制寄存器范围，写入两组已观察到的 SPI 命令/数据，再反复
// 发布 D，直到会合状态可见，最后跳转至 ARM7 返回入口。
//
// 这样 FP2 成为第二阶段策略与 IPC 顺序的唯一来源，而 FP1 负责 ARM9 侧响应。FP2 在
// 热启动路径中让零售 P2 主体保持其原始运行入口，正如 FP1 保留零售 P1 一样；添加前置
// 代码不会搬移任一保留主体。
