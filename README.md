# Nintendo DS custom firmware sources

[简体中文](README.zh-cn.md)

## About

`dscfw` is a Nintendo DS custom-firmware source repository.  It contains no
official Nintendo firmware image or other original binary image data.

The repository currently reconstructs source builds for Loopy's FlashMe and
Lost Nintendo History's DS Lite TV-out firmware modification.  These are
historical reconstruction projects, not official Nintendo firmware releases.

## Building the historical reconstructions

Supply your own Nintendo firmware dumps in the `dscfw` repository root as
`official_v3.bin` and `official_v6.bin`.  Run `make` in the applicable
`flashme` or `tvout` directory to build its recorded variants.

The build checks the supplied base firmware using fixed normalized CRC-32
records.  Historical FlashMe and TV-out variants with reference CRC records
then report whether the generated image matches the released firmware's
effective bytes.  Console-private Wi-Fi calibration, MAC-address, access-point
and user-setting data are intentionally not stored or treated as shared image
data; a raw whole-image comparison across consoles is therefore not implied.

See [flashme/README.md](flashme/README.md) and [tvout/README.md](tvout/README.md)
for the available packages and exact build rules.

## Regional builds and future work

iQue- and Korean-firmware FlashMe ports are now included under [`wokann/`](wokann/):

- [`wokann/flashme_v7_new/`](wokann/flashme_v7_new/) contains V7 New builds for
  iQue V1 Phat, plus iQue V2 Lite and Korean V1 Lite.
- [`wokann/flashme_v8a/`](wokann/flashme_v8a/) contains V8a builds for iQue V1
  Phat, plus iQue V2 Lite and Korean V1 Lite.
- [`wokann/tvout_v8a/`](wokann/tvout_v8a/) contains the V8a Lite TV-out builds
  for iQue V2 Lite and Korean V1 Lite.

The remaining longer-term goal is to provide Nintendo DS homebrew template
projects that build from source with development tools such as devkitPro,
rather than relying on recovered firmware binaries.
