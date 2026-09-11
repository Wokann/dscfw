// Stage 1 ARM7 half: the primary coordinator paired with the parked ARM9 P1.
// H starts both components concurrently.  This code chooses and prepares the
// continuation which releases P1 through its mutable P1 +0x08 literal slot.
// It changes from ARM to Thumb at +0x08; see main.s for the complete timeline.
// 第一阶段的 ARM7 一半：与等待中的 ARM9 P1 配对的一级协调器。H 会并行启动两个
// 组件；本代码负责选择并准备续接地址，再经由 P1 +0x08 的可修改字面量槽放行 P1。
// 它会在 +0x08 从 ARM 切换到 Thumb；完整时序请先阅读 main.s。
.create "build/p2.bin", 0
    .headersize PrimaryP2RamAddress
    .arm
    adr r0, p2_thumb + 1
    bx r0

    .thumb

p2_thumb:
    mov r11, r12
    mov r1, #0
    mov r2, #1
    bl p2_swi
    mov r1, #0x0d
    mov r2, #0
    bl p2_swi
    // The label form retains the historical Thumb word while ARMIPS derives its
    // PC-relative displacement.
    // 标签形式会保留历史 Thumb 指令字，并由 ARMIPS 推导其 PC 相对位移。
    adr r7, p2_boot_parameters_data
    ldmia r7!, {r0-r2, r4-r6}
    ldrh r1, [r1]
    lsl r1, r1, #28
    beq p2_copy_boot
    ldr r1, [r6]
    cmp r1, r2
    bne p2_service_boot

p2_copy_boot:
    ldmia r7!, {r0-r4}
    stmia r3!, {r0-r2}
    // Release the parked ARM9 gate through P1's mutable literal word.
    // 通过 P1 的可修改字面量字放行处于等待状态的 ARM9 闸门。
    str r0, [r4, #PrimaryP1ReleaseSlotOffset]
    add r6, #0x14
    b p2_handoff

p2_swi:
    ldr r3, [p2_slot_swi_routine]
    mov r0, #0
    bx r3

    .orga 0x3a
p2_boot_parameters:
    // The first six words are loaded by p2_thumb: FH image address, key input,
    // the Slot-2 marker, the ARM7 BIOS reader, the Thumb LZ77 entry, and the
    // Slot-2 title location.  p2_copy_boot then consumes the following five
    // words to construct the small ARM9 trampoline at 0x023FFE24.
    // 前六个字由 p2_thumb 读取：FH 的镜像地址、按键输入、Slot-2 标记、ARM7 BIOS
    // 读取例程、Thumb LZ77 入口及 Slot-2 标题位置。随后 p2_copy_boot 会使用后面
    // 五个字，在 0x023FFE24 构造小型 ARM9 跳板。
    .dh 0x0000
p2_boot_parameters_data:
    .dw FlashMePrimaryHeaderAddress, REG_KEYINPUT
    .ascii "BOOT"
    .dw BiosCopyRoutine, 0x00002a2b, 0x080000ac
    // ARM trampoline copied by the alternate route before the shared hand-off.
    // The named target slot lets armips compute the backward PC displacement.
    // 兼容分支会在进入共同交接尾部前复制这段 ARM 跳板。命名目标槽使 armips 自动
    // 计算向后的 PC 位移。
p2_arm9_trampoline_entry:
    .dw 0x023ffe28
    .arm
p2_arm9_trampoline_load:
    ldr r0, [p2_arm9_trampoline_entry]
    bx r0
    .thumb
p2_arm9_trampoline_return_slot:
    .dw 0x023ffe24
p2_arm9_trampoline_primary_p1:
    .dw PrimaryP1RamAddress

    .orga 0x68
p2_service_boot:
    // FH component route.  r11 retains the header work pointer received in r12;
    // the BIOS reader overlays its leading fields with the secondary FH data.
    // FH 组件路径。r11 保留了从 r12 传入的头工作区指针；BIOS 读取例程会用二级 FH
    // 数据覆盖其开头字段。
    mov r1, r11
    mov r2, #0x70
    bl p2_compute
    mov r7, r11
    ldrh r4, [r7, #0x14]
    ldr r1, [p2_slot_part1_ram_base]
    bl p2_compute_address
    ldr r1, [p2_slot_part2_ram_base]
    lsr r4, r4, #6
    add r7, #4
    bl p2_compute_address
    pop {r6, r7}
    ldr r4, [p2_slot_primary_p1_ram]
    // r7 is the ARM9 continuation yielded by the retail loading path.  Updating
    // this word is what wakes P1; it is not an ordinary cross-CPU function call.
    // r7 是零售加载路径产生的 ARM9 续接地址。更新该字才会唤醒 P1；这不是普通的
    // 跨 CPU 函数调用。
    str r7, [r4, #PrimaryP1ReleaseSlotOffset]

p2_handoff:
    mov lr, r6
    mov r0, sp
    mov r1, r11
    mov r2, #0xff
    ldr r4, [p2_slot_compute_routine]

p2_compute:
    bx r4

p2_compute_address:
    ldrh r0, [r7, #0x0c]
    ldrh r2, [r7, #0x0e]
    lsl r3, r4, #29
    lsr r3, r3, #29
    lsl r0, r3
    lsl r0, r0, #2
    lsl r3, r4, #26
    lsr r3, r3, #29
    lsl r2, r3
    lsl r2, r2, #2
    sub r1, r1, r2
    adr r3, p2_legacy_callback_table
    push {r1}
    bx r5

    .orga 0xb2
// Thumb-1 ABI bridge used inside the inherited BIOS/LZ77 serial-read path.  It
// serves that path's SPI transfer callback; it is not a separate boot stage.
// 这是继承的 BIOS/LZ77 串行读取路径内部使用的 Thumb-1 ABI 桥接。它提供该路径所需
// 的 SPI 传输回调，并不是另一个独立的引导阶段。
p2_legacy_thunk:
    push {r0, lr}
    mov r2, #0
    ldr r3, [p2_slot_legacy_call]
    bl p2_legacy_call
    mov r0, sp
    mov r1, #4
    mov r2, #1
    ldr r3, [p2_slot_legacy_copy]
    bl p2_legacy_call
    ldr r1, [p2_slot_spidata]
    strh r0, [r1]
    pop {r0, r3}

p2_legacy_call:
    bx r3

p2_legacy_wait:
    ldr r1, [p2_slot_spicnt]

p2_legacy_wait_busy:
    ldrh r0, [r1]
    lsr r0, r0, #8
    bcs p2_legacy_wait_busy
    ldrb r0, [r1, #2]
    strh r0, [r1, #2]
    bx lr

    .orga 0xe0
    // The table is the named ADR target in p2_compute_address.  Keep its three
    // historical values before the explicitly ordered slots.
    // 该表是 p2_compute_address 的命名 ADR 目标。其三个历史值必须位于显式槽之前。
p2_legacy_callback_table:
    .dw p2_legacy_thunk + 1
    .dw PrimaryP2LegacyCallbackValue
    .dw p2_legacy_wait + 1

    // Keep these explicitly ordered slots at the former pool location (+0xEC).
    // 命名槽保持在原池的位置和顺序（+0xEC）。
p2_slot_swi_routine:
    .dw PrimaryP2SwiRoutine
p2_slot_part1_ram_base:
    .dw FirmwarePart1RamaddrBase
p2_slot_part2_ram_base:
    .dw FirmwarePart2RamaddrBase
p2_slot_primary_p1_ram:
    .dw PrimaryP1RamAddress
p2_slot_compute_routine:
    .dw PrimaryP2ComputeRoutine
p2_slot_legacy_call:
    .dw PrimaryP2LegacyCallRoutine
p2_slot_legacy_copy:
    .dw PrimaryP2LegacyCopyRoutine
p2_slot_spidata:
    .dw REG_SPIDATA
p2_slot_spicnt:
    .dw REG_SPICNT
p2_primary_end:
    // The primary ARM7 coordinator must remain inside its 2 KiB bootstrap window.
    // 一级 ARM7 协调器必须始终位于其 2 KiB 引导窗口之内。
    .if p2_primary_end > FirmwarePart2RamaddrBase
        .error "FlashMe: primary P2 exceeds its staging window"
    .endif
.close

// =============================================================================
// C flow model (English)
// =============================================================================
// This is one comment-only C representation of the primary ARM7 coordinator.
// The formulas mirror include/symbol.inc: source shift_amounts decodes retail
// entries, while the final component layout is passed in as derived data.  The
// real serial reader/LZ77/shared-tail path has a register-and-stack ABI, so it
// is represented by typed callbacks instead of pretending it is normal C ABI.
//
// =============================================================================
// C 流程模型（中文）
// =============================================================================
// 这是一级 ARM7 协调器的一份仅作注释的 C 表达。公式镜像 include/symbol.inc：源
// shift_amounts 用于解码零售入口，最终组件布局以已推导数据传入。真实的串行读取器/
// LZ77/共同尾部使用寄存器和栈 ABI，因此以类型化回调表示，而不会伪装为普通 C ABI。
//
// // Nintendo DS firmware format / DS 固件格式固定值。
// #define NDS_FIRMWARE_PART1_RAM_BASE          0x02800000u
// #define NDS_FIRMWARE_PART2_RAM_BASE          0x03810000u
//
// // FlashMe layout formulas / FlashMe 布局推导公式。
// #define FLASHME_PART1_RAM_SHIFT(shifts)      (2u + (((shifts) >> 3) & 7u))
// #define FLASHME_PART2_RAM_SHIFT(shifts)      (2u + (((shifts) >> 9) & 7u))
// #define FLASHME_PART1_RAM_FROM_FIELD(f, s)   \
//     (NDS_FIRMWARE_PART1_RAM_BASE - ((uintptr_t)(f) << FLASHME_PART1_RAM_SHIFT(s)))
// #define FLASHME_PART2_RAM_FROM_FIELD(f, s)   \
//     (NDS_FIRMWARE_PART2_RAM_BASE - ((uintptr_t)(f) << FLASHME_PART2_RAM_SHIFT(s)))
//
// typedef struct __attribute__((packed)) {
//     u8 reserved00To0b[0x0c];
//     u16 part1SourceField, part1RamField;
//     u16 part2SourceField, part2RamField;
//     u16 shiftAmounts;
// } FirmwareHeaderPrefix;
//
// typedef struct {
//     uintptr_t primaryP1Ram;
//     uintptr_t arm9TrampolineRam;
//     const void *flashHeaderImage;
//     FirmwareHeaderPrefix *headerWork;
//     const u8 *slot2Title;
// } FlashMePrimaryArm7Layout;
//
// static PartDescriptor DecodePart1(const FirmwareHeaderPrefix *header)
// {
//     return (PartDescriptor) {
//         .compressedSourceOffset = (u32)header->part1SourceField <<
//             (2u + ((header->shiftAmounts >> 0) & 7u)),
//         .ramDestination = FLASHME_PART1_RAM_FROM_FIELD(
//             header->part1RamField, header->shiftAmounts),
//     };
// }
//
// static PartDescriptor DecodePart2(const FirmwareHeaderPrefix *header)
// {
//     return (PartDescriptor) {
//         .compressedSourceOffset = (u32)header->part2SourceField <<
//             (2u + ((header->shiftAmounts >> 6) & 7u)),
//         .ramDestination = FLASHME_PART2_RAM_FROM_FIELD(
//             header->part2RamField, header->shiftAmounts),
//     };
// }
//
// static void InstallArm9Trampoline(const FlashMePrimaryArm7Layout *layout)
// {
//     volatile u32 *const trampoline = (volatile u32 *)layout->arm9TrampolineRam;
//
//     // English: P1 consumes the first word as its next ARM9 continuation.
//     // 中文：P1 会把第一个字作为下一 ARM9 续接地址。
//     trampoline[0] = layout->arm9TrampolineRam + sizeof(u32);
//     trampoline[1] = 0xe51f000c;
//     trampoline[2] = 0xe12fff10;
//     *(volatile u32 *)(layout->primaryP1Ram + 0x08) = trampoline[0];
// }
//
// static __attribute__((noreturn)) void PrimaryP2Coordinator(
//     const FlashMePrimaryArm7Layout *layout, const RetailP2Abi *retail)
// {
//     retail->sendIpc(0, 0, 1);
//     retail->sendIpc(0, 0x0d, 0);
//
//     const bool alternateRoute = ((REG_KEYINPUT & 0x000f) == 0) ||
//         memcmp(layout->slot2Title, "BOOT", 4) == 0;
//
//     if (alternateRoute) {
//         // English: The Slot-2-compatible path creates and publishes a trampoline.
//         // 中文：兼容 Slot-2 的路径会创建并发布跳板。
//         InstallArm9Trampoline(layout);
//         retail->enterSharedTail((uintptr_t)layout->slot2Title + 0x14,
//                                 layout->headerWork, 0xff);
//         __builtin_unreachable();
//     }
//
//     retail->readHeader(layout->flashHeaderImage, layout->headerWork, 0x70);
//     const PartLoadResult loaded = retail->loadParts(
//         DecodePart1(layout->headerWork), DecodePart2(layout->headerWork),
//         layout->headerWork);
//
//     // English: Publishing this word is the release operation for parked P1.
//     // 中文：发布此字就是放行等待中 P1 的操作。
//     *(volatile u32 *)(layout->primaryP1Ram + 0x08) = loaded.arm9Continuation;
//     retail->enterSharedTail(loaded.arm7Continuation, layout->headerWork, 0xff);
//     __builtin_unreachable();
// }

// =============================================================================
// Coordination and design analysis (English)
// =============================================================================
// P2 is the owner of the entire first-stage decision.  It begins beside the
// parked P1, preserves the r12 header-work pointer, performs the two inherited
// IPC preparations, and then selects between two routes.  The low-four-key and
// Slot-2 "BOOT" tests are not independent boots: both choose the alternate
// branch that first writes a three-word ARM9 trampoline and publishes its entry
// through P1 +0x08.  The ARM7 side then enters its corresponding inherited
// continuation through the common tail.
//
// On the normal route, P2 uses the inherited reader to overlay the beginning of
// its header work area with FH.  The source/RAM fields are interpreted with the
// separate shift_amounts bit groups, so FH describes where FP1 and FP2 are read
// from and where they run.  The inherited reader/LZ77 path yields an ARM7 and an
// ARM9 continuation.  P2 writes only the ARM9 result into P1's release word;
// the common tail receives the ARM7 result and continues that CPU's state.
//
// This division prevents two loaders from competing on ARM9.  P2 alone owns
// route selection, FH interpretation, and the release write; P1 only waits;
// FP1/FP2 are not started until P2 has completed the relevant first-stage work.
// H therefore describes the small coordinator pair, while FH describes the
// second pair that P2 selects and loads.
//
// =============================================================================
// 协同与设计解析（中文）
// =============================================================================
// P2 是整个第一阶段决策的主控端。它与等待中的 P1 并行开始，保留 r12 头工作区指针，
// 执行两次继承的 IPC 准备，随后在两条路径之间选择。低四位按键与 Slot-2 的 "BOOT"
// 测试并不是两个彼此独立的引导：它们都会选择兼容分支，先写入三字 ARM9 跳板，再经由
// P1 +0x08 发布其入口。ARM7 侧随后会通过共同尾部进入相应的继承续接。
//
// 在普通路径中，P2 使用继承读取器以 FH 覆盖头工作区的开头。源/RAM 字段会依据彼此
// 独立的 shift_amounts 位组解释，因此 FH 说明 FP1/FP2 从何处读取、在何处运行。继承的
// 读取器/LZ77 路径会产生 ARM7 与 ARM9 两个续接地址。P2 只把 ARM9 结果写入 P1 的放行
// 字；共同尾部接收 ARM7 结果并继续该 CPU 的状态。
//
// 这种职责分离避免两个加载器在 ARM9 上竞争。只有 P2 负责路径选择、FH 解释和放行写入；
// P1 只等待；FP1/FP2 只有在 P2 完成相关第一阶段工作后才会开始。因此 H 描述的是小型
// 协调器对，而 FH 描述的是由 P2 选择并加载的第二对组件。
