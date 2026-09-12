# FlashMe version change log

[简体中文](CHANGELOG.zh-cn.md)

## Scope and reading guide

This is a user-facing record of the behaviours visible in the recovered
FlashMe V1, V3–V8a code. It is based primarily on the reconstructed assembly
and the Nintendo V3/V6 code it changes, rather than treating old release-page
descriptions as proof. “Confirmed” below means that the branch, data flow, or
hardware action is visible in code; an explicitly marked uncertainty is not a
missing-feature claim.

The source tree does not distribute Nintendo firmware or original FlashMe
images. V2 has no original image or source available here, so it is not
reconstructed and no functional claim is made for it.

## Behaviour present from V1 onward

The recovered V1 already contains the principal FlashMe design, retained by
later versions unless a version entry below says otherwise:

- **Slot-2 DS-program boot.** A Slot-2/GBA ROM whose Game Code is `PASS`, or
  whose title begins with `DSBooter`, automatically selects the FlashMe boot
  path. Holding `A+B+X+Y` forces that path even when the Slot-2 header does
  not carry either identifier.
- **Retained-firmware boot.** In the ordinary selector, holding `Select`
  chooses the retained Nintendo-firmware path instead of the FlashMe path.
- **Early recovery entry.** `BOOT` as the Slot-2 Game Code is tested before
  `PASS`/`DSBooter`; V1–V8 also select an earlier alternate route when
  `A+B+Start+Select` are held. This is the firmware-side entry that a
  Slot-2 recovery/flashing program can use; the program which repairs a
  damaged firmware is external to FlashMe itself.
- **Relaxed firmware validation.** The retained Nintendo P1/P3 code has
  component-integrity gates bypassed, and the P3 public-key formatted-digest
  and SHA-1-style digest-comparison entries return success. In practical
  terms, this removes the corresponding Nintendo signature-validation barrier
  for the affected NDS-program path.
- **Normal boot presentation.** The normal V1 path contains a PWM backlight
  fade-in sequence. There is no separate stealth build in V1.

## Version-by-version changes

### V1 — initial recovered feature set

V1 establishes the complete two-stage FlashMe loader, the Slot-2 automatic and
manual selectors, the early recovery entry, and the validation bypasses above.
Its normal path also performs the backlight fade-in. The exact Nintendo UI
scene affected by one retained-P3 Logo/state gate is not named solely from the
code; it must not be presented as a separately proven “health-screen” patch.

### V2 — unavailable

No original V2 image or source has been found for this repository. It is
intentionally omitted rather than simulated from forum recollections or from
the adjacent V1/V3 builds.

### V3 — normal startup-transition change

V3 preserves the V1 core behaviour and adds four normal-only edits to the
retained Nintendo P1 alpha-transition path. A user sees a changed startup
display transition in the normal build. The code proves the alpha-dispatch,
threshold, and terminal-branch changes, but does not by itself identify the
exact on-screen scene; therefore this changelog does not claim V3 as the first
proven version to remove a particular health-warning screen.

### V4 — normal and stealth become separate builds

V4 introduces the two user-selectable presentation policies used by later
versions:

- **normal** keeps the V3-style transition edits and the normal fade-in path;
- **stealth** leaves those retained-P1 alpha bytes unmodified and skips the
  normal PWM fade-in loop, preserving the more stock-like startup-display
  route conventionally associated with FlashMe Stealth.

V4 also adds a touch-controller SPI transaction during the FlashMe path. Its
result is not consumed, so no separate user-visible purpose can be established
from the recovered code.

### V5 — loader-layout and installer-recognition update

No new end-user boot control is confirmed over V4. V5 changes the internal
first/second-stage hand-off layout and moves the secondary header location. It
also starts the V5-and-later installer identification scheme, so compatible
installers can distinguish the V5+ family instead of treating it as the older
undifferentiated FlashMe class.

### V6 — revised early-start preparation

V6 retains the normal/stealth choices and changes cold-start preparation: it
restores a boot-complete flag write, conditionally prepares a standard NDS
header/Logo area in RAM, and restores an earlier call ordering before the SPI
sequence. These are concrete compatibility/initialisation changes, but the
recovered code does not establish one new, independently visible user feature.

### V7 Old — Phat/Lite split and an additional matching-card boot path

V7 Old introduces separate Phat and Lite builds. When the usual Slot-2
selectors do not choose FlashMe, its normal path can probe an auxiliary
device/card, validate an NDS header, and directly launch its ARM9 and ARM7
payloads. This is an additional boot path for a matching device, not a generic
claim that every Slot-1 card is booted this way: its handshake uses non-standard
commands and the exact target hardware remains unidentified.

### V7 New — Phat stealth hardware-protocol revision

The recovered Lite prefix is unchanged from V7 Old. V7 New Phat changes SPI
setup, response handling, and a write helper in its stealth cold-start path.
It is a real code change, but its high-level hardware target and a distinct
user-visible consequence are not established by the available code.

### V8 — noauto variants; V7 auxiliary-card entry removed

V8 adds two more build variants:

- **noauto** disables automatic `PASS`/`DSBooter` selection; FlashMe must be
  selected manually with `A+B+X+Y`.
- **stealth_noauto** combines that manual-selection policy with stealth's
  stock-like presentation route.

The normal and stealth variants retain automatic `PASS`/`DSBooter` selection.
V8 also removes every normal FP2 entry into V7's auxiliary/card loader, so the
V7 matching-device boot attempt is no longer made by the ordinary V8 selector.
On Lite normal builds, the previous PWM backlight fade loop is replaced with a
fixed delay.

### V8a — revised manual selection and standard card loader

V8a changes both the early alternate boot path and the noauto control:

- its early alternate route is selected by `Start+Select` or the earlier
  `BOOT` Game Code test, replacing the V1–V8 `A+B+Start+Select` combination;
- in **noauto** and **stealth_noauto**, holding `Select` selects FlashMe,
  replacing V8's `A+B+X+Y` requirement;
- its primary stage adds a standard `B7`-based Slot-1 NDS loader, using the
  NDS header's ARM9/ARM7 load and entry fields when that route is selected;
- cold preparation also clears the main and sub display-control registers.

The older installer metadata still reports V8a as V8. That is a limitation of
the V5+ identifier scheme, not evidence that the two builds behave identically.

## Variant summary

| Variant | User-visible policy |
| --- | --- |
| `normal` | Standard FlashMe automatic Slot-2 selection and normal startup presentation for that version. |
| `stealth` | Uses the stock-like startup-display route instead of normal's transition/fade modifications. |
| `noauto` | Requires an explicit user action instead of automatic `PASS`/`DSBooter` selection: `A+B+X+Y` in V8, `Select` in V8a. |
| `stealth_noauto` | Combines stealth presentation with noauto manual selection. |

## Evidence and limits

The detailed branch-level evidence, component offsets, Nintendo V3/V6 semantic
mapping, and explicitly unresolved questions are recorded in
[FUNCTIONAL_ANALYSIS.md](FUNCTIONAL_ANALYSIS.md). The RSA conclusion follows
the recovered PKCS#1-v1.5-shaped formatted-digest path and the independent
[RFC 8017 specification](https://www.rfc-editor.org/rfc/rfc8017.html#section-8.2).
Hardware register interpretations are cross-checked against
[GBATEK](https://raw.githubusercontent.com/mgba-emu/gbatek/master/ds.md).
