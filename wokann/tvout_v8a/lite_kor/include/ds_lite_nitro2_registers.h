#pragma once

/*
 * Source / 来源：
 * melonDS forum, “GBAtek addendum/errata”, post #5772 (2023-01-16):
 * https://melonds.kuribo64.net/board/thread.php?pid=5772
 * Published by Generic aka RSDuck.  The post states:
 * “DSlite specific registers, provided by Gericom”.
 * 发布者为 Generic（RSDuck）；帖文声明此 DS Lite 寄存器资料由 Gericom 提供。
 * The original first-party Gericom publication has not been located.
 * 尚未找到 Gericom 更早的一手公开发布位置。
 */

// As far as known, these registers exist only on DS Lite.
// 据已知资料，这些寄存器仅存在于 DS Lite。
// The retail firmware writes 0xFFFF to REG_REGCNT during boot, preventing
// later reads and writes below because REG_REGCNT is write-once.
// 原厂固件启动时向 REG_REGCNT 写入 0xFFFF；该寄存器仅能写入一次，
// 之后会禁止对下列寄存器的读写。

// Lockout register for Nitro2 features: write-only and write-once.
// Nitro2 功能锁定寄存器：只写且只能写入一次。
#define REG_REGCNT          (*(vu16 *)0x04001080)
#define REGCNT_WE0          (1 << 0)  // Disables writing to REG_DISPCNT2.
#define REGCNT_WE1          (1 << 1)  // Disables writing to REG_DISPSW.
#define REGCNT_WE2          (1 << 2)  // Disables writing to REG_CLK11M.
#define REGCNT_RE0          (1 << 8)  // Disables reading from REG_DISPCNT2.
#define REGCNT_RE1          (1 << 9)  // Disables reading from REG_DISPSW.
#define REGCNT_RE2          (1 << 10) // Disables reading from REG_CLK11M.

// Selects dual- or single-screen mode / 选择双屏或单屏模式。
#define REG_DISPCNT2        (*(vu16 *)0x04001090)
#define DISPCNT2_MOD_DUAL_SCREEN    0 // Default: two screens.
#define DISPCNT2_MOD_SINGLE_SCREEN  1 // Disables top LCD; enables special features.

// Configures single-screen mode.  “main” and “sub” mean configurable screens,
// not the DS main/sub graphics engines.
// 配置单屏模式；main/sub 指可配置的屏幕，不是 DS 主/副图形引擎。
#define REG_DISPSW          (*(vu16 *)0x040010A0)

#define DISPSW_WIN_SHIFT    0
#define DISPSW_WIN_MASK     (3 << DISPSW_WIN_SHIFT)
#define DISPSW_WIN(x)       ((x) << DISPSW_WIN_SHIFT)
#define DISPSW_WIN_MAIN_ONLY                   0 // Main screen only.
#define DISPSW_WIN_MAIN_FULL_SUB               1 // Blend main and sub screens.
#define DISPSW_WIN_MAIN_HALF_SUB_BOTTOM_LEFT   2 // 128x96 sub screen, bottom-left.
#define DISPSW_WIN_MAIN_HALF_SUB_BOTTOM_RIGHT  3 // 128x96 sub screen, bottom-right.

#define DISPSW_A_SHIFT      4
#define DISPSW_A_MASK       (3 << DISPSW_A_SHIFT)
#define DISPSW_A(x)         ((x) << DISPSW_A_SHIFT)
// Blend ratio in DISPSW_WIN_MAIN_FULL_SUB mode / 全屏混合比例。
#define DISPSW_A_FULL_7_1   0 // Main 7/8, sub 1/8.
#define DISPSW_A_FULL_6_2   1 // Main 6/8, sub 2/8.
#define DISPSW_A_FULL_5_3   2 // Main 5/8, sub 3/8.
#define DISPSW_A_FULL_4_4   3 // Main 4/8, sub 4/8.
// Blend ratio in half-sub modes / 小窗模式混合比例。
#define DISPSW_A_HALF_3_1   0 // Main 3/4, sub 1/4.
#define DISPSW_A_HALF_2_2   1 // Main 2/4, sub 2/4.
#define DISPSW_A_HALF_1_3   2 // Main 1/4, sub 3/4.
#define DISPSW_A_HALF_0_4   3 // Main 0/4, sub 4/4.

// Selects TV screen when TV-out is enabled / 选择送往 TV 的屏幕。
#define DISPSW_M0_SHIFT     8
#define DISPSW_M0_MASK      (1 << DISPSW_M0_SHIFT)
#define DISPSW_M0(x)        ((x) << DISPSW_M0_SHIFT)
#define DISPSW_M0_TV_SUB    0 // Output sub screen to TV-out.
#define DISPSW_M0_TV_MAIN   1 // Output main screen to TV-out.

// Selects which source is main or sub / 指定哪一路为 main 或 sub。
#define DISPSW_M1_SHIFT                     9
#define DISPSW_M1_MASK                      (1 << DISPSW_M1_SHIFT)
#define DISPSW_M1(x)                        ((x) << DISPSW_M1_SHIFT)
#define DISPSW_M1_MAIN_BOTTOM_SUB_TOP       0
#define DISPSW_M1_MAIN_TOP_SUB_BOTTOM       1

// TV-out enable/disable / TV-out 开关。
#define DISPSW_TVOUT_SHIFT      14
#define DISPSW_TVOUT_MASK       (1 << DISPSW_TVOUT_SHIFT)
#define DISPSW_TVOUT(x)         ((x) << DISPSW_TVOUT_SHIFT)
#define DISPSW_TVOUT_DISABLED   0 // Top screen is white.
#define DISPSW_TVOUT_ENABLED    1 // Top-screen signals carry 10-bit digital NTSC.

// In single-screen mode, three top-screen signals are button inputs.  Hardware
// changes WIN, A and M0/M1 when pressed; this bit disables that behaviour.
// 单屏模式下三条顶屏信号可作按键输入；硬件可修改 WIN、A、M0/M1，
// 设置此位后将禁用该按键行为。
#define DISPSW_KEYLOCK_SHIFT    15
#define DISPSW_KEYLOCK_MASK     (1 << DISPSW_KEYLOCK_SHIFT)
#define DISPSW_KEYLOCK(x)       ((x) << DISPSW_KEYLOCK_SHIFT)
#define DISPSW_KEYLOCK_DISABLED 0
#define DISPSW_KEYLOCK_ENABLED  1

// Outputs an 11 MHz clock on the SoC CLK11M pin / 在 SoC CLK11M 引脚输出 11 MHz 时钟。
#define REG_CLK11M          (*(vu16 *)0x040010B0)
#define CLK11M_CK11_LOW     0
#define CLK11M_CK11_ACTIVE  1
