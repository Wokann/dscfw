# FlashMe Version Change Log

[简体中文](CHANGELOG.zh-cn.md)

## Functional changes by version

### V1

- **Booting a Slot-2 DS program.** If the Slot-2/GBA ROM Game Code is <code>PASS</code>, or its Game Title begins with <code>DSBooter</code>, FlashMe automatically treats it as a DS program and boots it at power-on. Holding <code>A+B+X+Y</code> forces this path even if neither marker is present in the Slot-2 header.
- **Booting the retained original firmware.** Holding <code>Select</code> at power-on enters the retained original Nintendo firmware.
- **Recovery boot entry.** If the Slot-2/GBA ROM Game Code is <code>BOOT</code>, or if <code>A+B+Start+Select</code> are held, a DS program on Slot-2 can be force-started at power-on. Because this code is located very early in the firmware, it can start a Slot-2 recovery program to reinstall firmware if that early portion has already been written during an interrupted flash, or if data outside SL1's protected first <code>0x10000</code> bytes becomes damaged after FlashMe is installed.
- **Wireless MultiBoot verification removed.** Removes the RSA verification check for Wireless MultiBoot (such as Download Play).
- **Original-firmware startup fade.** When booting retained original firmware, the display fades from black to white and then shows the health and safety prompt. (Slot-2 DS mode instead proceeds directly with a white screen into the corresponding game or flash cartridge.)
- **Base firmware.** Based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>).

### V2

- No original V2 image backup has been found. Forum material about functional changes from V1 to V3 also contains errors, so a functional reconstruction cannot be attempted.
- **V1-to-V2 upgrades do not require SL1 bridging.** FlashMe changes try to avoid modifying content stored at the front of the firmware, altering only the later region. Thus, SL1 must be bridged only for initial installation from official firmware to FlashMe, to release protection of the first <code>0x10000</code> bytes. Later upgrades do not require bridging provided that range is unchanged. (Forum records establish this information as reliable.)
- **Base firmware.** Based on official DS Phat V3 firmware.

### V3

- **Health prompt removed.** When booting retained original firmware, the black-to-white fade remains, but the health and safety prompt is no longer shown afterward.
- **V1-to-V3 upgrades do not require SL1 bridging.** The first <code>0x10000</code> bytes are identical in V1 through V3, so upgrades do not require bridging.
- **Base firmware.** Based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>).

### V4

V4 provides two distinct builds according to whether the health prompt is shown:

- **normal build:** Removes the health prompt while retaining the startup fade when booting retained original firmware.
- **stealth build:** Retains the health prompt while removing the startup fade. “Stealth” means concealing that the console has been reflashed.

Other changes:

- **V1-to-V4 upgrades do not require SL1 bridging.** The first <code>0x10000</code> bytes are identical in V1 through V4, so upgrades do not require bridging.
- **Base firmware.** Based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>).
- V4 contains one touchscreen-controller SPI operation, but the code does not use its returned value; its purpose remains unknown.

### V5

- **Two builds retained.** normal and stealth continue as separate releases.
- **Wi-Fi-settings-area fix.** In V1 through V4, FlashMe's secondary boot-header file occupied an address range later used to store Wi-Fi access-point data. After the first Wi-Fi-enabled game, <em>Mario Kart DS</em>, was released, players with older FlashMe versions could experience a bricked console. V5 moves the occupied secondary boot-header range earlier, avoiding that data.
- **Upgrading V1-V4 to V5 requires SL1 bridging.** The first <code>0x10000</code> bytes change in V5, so V1-V4 consoles must bridge SL1 before upgrading.
- **Installer internal version-class update.** Within <code>flashme.nds</code>, V1-V4 are treated as one class: byte <code>0x17C</code> in the firmware file header is <code>1</code> (class 1), and byte <code>0x17C</code> in the secondary boot-file header at the end of the firmware is also <code>1</code> (fixed 1). From V5 onward, byte <code>0x17C</code> in the firmware file header is <code>2</code> (class 2), and byte <code>0x17C</code> in the secondary boot-file header is <code>2</code> (that value plus 3 is the version number). A value of <code>3</code> in the firmware file header denotes hbfirmware custom firmware; the secondary boot-file header then contains <code>0xFF</code>.
- **Base firmware.** Based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>).

### V6

- **Internal logic improvements.** In theory, there are no clearly user-visible functional changes.
- **V5-to-V6 upgrades do not require SL1 bridging.** The first <code>0x10000</code> bytes are identical in V5 and V6, so upgrades do not require bridging.
- **Base firmware.** Based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>).

### V7 Old Phat

- **NeoFlash MK2/MK3 support.** Supports directly booting Slot-1 NeoFlash MK2 and MK3 flash cartridges from FlashMe; DSLINK can also be booted.
- **V5-to-V7 Old Phat upgrades do not require SL1 bridging.** The first <code>0x10000</code> bytes are identical in V5 through V7 Old Phat, so upgrades do not require bridging.
- **Base firmware.** Based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>).

### V7 Old Lite

- **Lite-model release.** DS Phat and DS Lite are different hardware types and use different official firmware, so V7 begins to provide separate Lite firmware. Forums report beta1 and beta2 Lite test versions, but only one version has been found. It is probably beta2, because the standalone V7 Lite installer contains firmware identical to the Lite image in the integrated V7 New installer.
- **NeoFlash MK2/MK3 support.** Supports directly booting Slot-1 NeoFlash MK2 and MK3 flash cartridges from FlashMe; DSLINK can also be booted.
- **V5-to-V7 Old Lite upgrades require SL1 bridging.** Lite and Phat versions differ in certain functions, including backlight behavior, although Lite firmware can be forcibly installed on a Phat. Their different base firmware means the first <code>0x10000</code> bytes necessarily differ, so a cross-model installation requires bridging. CPU20 Phat boards use the same power-management controller as the Lite, so installing Lite firmware gives them the Lite's four-level brightness control.
- **Base firmware.** Based on official DS Lite V6 firmware (<code>USG-WORLD WIDE-Ver2.0</code>).

### V7 New

- **Installer integrates both models.** From this version, <code>flashme.nds</code> includes both Phat and Lite firmware and distinguishes the current console by checking its power-management controller. A CPU20 Phat is consequently identified as a Lite and gains four-level brightness control.
- **NeoFlash MK2/MK3 support.** Supports directly booting Slot-1 NeoFlash MK2 and MK3 flash cartridges from FlashMe; DSLINK can also be booted.
- **Phat route: V5-to-V7 upgrades do not require SL1 bridging.** The first <code>0x10000</code> bytes are identical in V5 through V7 Phat, so upgrades do not require bridging. Cross-model flashing still requires bridging.
- **Base firmware.** Phat is based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>); Lite is based on official DS Lite V6 firmware (<code>USG-WORLD WIDE-Ver2.0</code>).

### V8

V8 adds noauto branches for whether Slot-2 cartridges are automatically booted. These branches also have normal and stealth forms:

- **normal:** Retains automatic <code>PASS</code>/<code>DSBooter</code> selection and the <code>A+B+X+Y</code> combination for forcing the FlashMe path. Removes the health prompt.
- **stealth:** Retains automatic <code>PASS</code>/<code>DSBooter</code> selection and the <code>A+B+X+Y</code> combination for forcing the FlashMe path. Retains the health prompt.
- **noauto:** Disables automatic <code>PASS</code>/<code>DSBooter</code> selection; <code>A+B+X+Y</code> must be held to enter FlashMe manually. Removes the health prompt.
- **stealth_noauto:** Disables automatic <code>PASS</code>/<code>DSBooter</code> selection; <code>A+B+X+Y</code> must be held to enter FlashMe manually. Retains the health prompt.
- **Booting the retained original firmware.** At power-on, holding <code>Select</code> enters the retained original firmware in every variant.
- **Lite startup fade removed.** From V3 onward, normal Lite builds used a black-to-white fade when entering retained firmware; V8 removes it, producing a fixed white-screen display instead. stealth and stealth_noauto retain V4's no-fade behavior. Phat retains its V4-era behavior.

Other changes:

- **NeoFlash MK2/MK3 support removed.** MK2 and MK3 flash cartridges, including DSLINK, are no longer supported. When the Slot-2 DS-mode path is not selected, the program sends a probe signal to the Slot-1 cartridge to determine whether it is an MK2/MK3-type card and whether it should subsequently boot it. This probe signal can cause unpredictable responses from non-target cartridges. Its removal is presumed to be for this reason.
- **Phat route: V5-to-V8 upgrades do not require SL1 bridging.** The first <code>0x10000</code> bytes are identical in V5 through V8 Phat, so upgrades do not require bridging. Cross-model flashing still requires bridging.
- **Lite route: V7-to-V8 upgrades do not require SL1 bridging.** The first <code>0x10000</code> bytes are identical in V7 through V8 Lite, so upgrades do not require bridging. Cross-model flashing still requires bridging.
- **Base firmware.** Phat is based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>); Lite is based on official DS Lite V6 firmware (<code>USG-WORLD WIDE-Ver2.0</code>).

### V8a

- **normal:** Retains automatic <code>PASS</code>/<code>DSBooter</code> selection and the <code>A+B+X+Y</code> combination for forcing the FlashMe path. Removes the health prompt.
- **stealth:** Retains automatic <code>PASS</code>/<code>DSBooter</code> selection and the <code>A+B+X+Y</code> combination for forcing the FlashMe path. Retains the health prompt.
- **noauto:** Disables automatic <code>PASS</code>/<code>DSBooter</code> selection; <code>Select</code> must be held to enter FlashMe manually. Removes the health prompt.
- **stealth_noauto:** Disables automatic <code>PASS</code>/<code>DSBooter</code> selection; <code>Select</code> must be held to enter FlashMe manually. Retains the health prompt.
- **Booting the retained original firmware.** Holding <code>Select</code> at power-on enters the retained original firmware. (The two noauto builds enter retained original firmware without a button; holding <code>Select</code> instead enters FlashMe.)
- **Recovery-entry change.** The recovery combination changes from <code>A+B+Start+Select</code> to <code>Start+Select</code>. Holding that combination, or using a Slot-2/GBA ROM whose Game Code is <code>BOOT</code>, attempts to force-start either a Slot-1 or Slot-2 cartridge.
- **Phat and Lite routes: upgrading any version before V8a to V8a requires SL1 bridging.** The first <code>0x10000</code> bytes in both V8a Phat and Lite differ from all V8 and earlier versions, so upgrading requires bridging before flashing the firmware.
- **Base firmware.** Phat is based on official DS Phat V3 firmware (<code>NTR-WORLD WIDE-Ver3.0</code>); Lite is based on official DS Lite V6 firmware (<code>USG-WORLD WIDE-Ver2.0</code>).

## Button-combination summary

| Version | Model | Variant | Combination to force the Slot-2 path | Combination to force retained official firmware | Early-start combination, normally used for recovery |
| --- | --- | --- | --- | --- | --- |
| <code>v1</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
| <code>v2</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
| <code>v3</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
| <code>v4</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>phat</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
| <code>v5</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>phat</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
| <code>v6</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>phat</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
| <code>v7_old</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>phat</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>lite</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>lite</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
| <code>v7_new</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>phat</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>lite</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>lite</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
| <code>v8</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>phat</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>phat</code> | <code>noauto</code> | <code>A+B+X+Y</code> | Not required | <code>A+B+Start+Select</code> |
|  | <code>phat</code> | <code>stealth_noauto</code> | <code>A+B+X+Y</code> | Not required | <code>A+B+Start+Select</code> |
|  | <code>lite</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>lite</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>A+B+Start+Select</code> |
|  | <code>lite</code> | <code>noauto</code> | <code>A+B+X+Y</code> | Not required | <code>A+B+Start+Select</code> |
|  | <code>lite</code> | <code>stealth_noauto</code> | <code>A+B+X+Y</code> | Not required | <code>A+B+Start+Select</code> |
| <code>v8a</code> | <code>phat</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>Start+Select</code> |
|  | <code>phat</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>Start+Select</code> |
|  | <code>phat</code> | <code>noauto</code> | <code>Select</code> | Not required | <code>Start+Select</code> |
|  | <code>phat</code> | <code>stealth_noauto</code> | <code>Select</code> | Not required | <code>Start+Select</code> |
|  | <code>lite</code> | <code>normal</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>Start+Select</code> |
|  | <code>lite</code> | <code>stealth</code> | <code>A+B+X+Y</code> | <code>Select</code> | <code>Start+Select</code> |
|  | <code>lite</code> | <code>noauto</code> | <code>Select</code> | Not required | <code>Start+Select</code> |
|  | <code>lite</code> | <code>stealth_noauto</code> | <code>Select</code> | Not required | <code>Start+Select</code> |
