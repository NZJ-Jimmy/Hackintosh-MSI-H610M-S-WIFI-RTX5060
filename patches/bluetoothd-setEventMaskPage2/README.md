# BlueToolFixup 2.7.2 + bluetoothd patches for Realtek USB Bluetooth (Sequoia 15.8.1 / 15.8.2)

## Problem

Once the Realtek controller is detected as `THIRD_PARTY_DONGLE` (see `../realtek-bt-dongle-mode`), bluetoothd aborts HCI init:

```
OI_HCICMD_SetEventMaskPage2 returned  STATUS 46 (status=628)
ERROR -- Third Party USB Bluetooth dongle failed initialization. Switching to internal Bluetooth module
Bluetooth error - restarting { reason=108, context="HCI initialization failed" }
```

The controller does not advertise *Set Event Mask Page 2* (Supported Commands octet 22 bit 2), so bluetoothd rejects the command locally and treats that as fatal. Linux skips the command in this case.

## Fix

Three in-memory patches to `/usr/sbin/bluetoothd`, applied through BlueToolFixup's existing `cs_validate_page` hook (see `BlueToolFixup-2.7.2-rtl.patch`):

| name | effect |
|---|---|
| emp2 | on local rejection, call `initCmdWriteEventMaskPage2Cb(0)` and continue init |
| scan_reset_loc3 | treat an LE scan reset error as success |
| scan_stop_error | treat an LE scan stop error as success |

The patterns come from [thegwchr/RealtekBluetoothFirmware#6](https://github.com/thegwchr/RealtekBluetoothFirmware/issues/6) (made for 15.8.2 / 24H232). They match bluetoothd of **15.8.1 / 24H32** exactly once each at identical addresses; the call target was verified by disassembly to be `initCmdWriteEventMaskPage2Cb`. Other macOS builds: the patterns simply do not match (no effect).

## Build

`ld64.lld` cannot emit `MH_KEXT_BUNDLE`, so the objects were compiled on Linux (clang 23, MacKernelSDK, Lilu 1.7.2 headers) and are linked on macOS with the Command Line Tools:

```
bash link-and-install-macos.command
```

The script checks the bluetoothd build (after undoing BlueToolFixup's own in-memory patches, which the running system shows through the page cache), links, checks the result (KEXTBUNDLE, no stray undefined symbols, patch table present), backs up and replaces `EFI/OC/Kexts/BlueToolFixup.kext` relative to this repo.

Compile flags used for the objects:

```
-target x86_64-apple-macos10.8 -Os -fno-builtin -fno-common -mkernel -nostdinc -nostdlib
-DKERNEL -DKERNEL_PRIVATE -DDRIVER_PRIVATE -DAPPLE -DNeXT -I MacKernelSDK/Headers -I <Lilu>/
-x c++ -std=gnu++14 -fno-rtti -fno-exceptions -fapple-kext -fno-use-cxa-atexit
-DLILU_CUSTOM_IOKIT_INIT=1 -DPRODUCT_NAME=BlueToolFixup -DMODULE_VERSION=2.7.2
```

Upstream clang lowers `llvm.global_dtors` to `__cxa_atexit`/`atexit` on Darwin, which the kernel does not export. `BlueToolFixup.o` was therefore built from LLVM IR in which the global dtor entry was moved into a pointer in `__DATA,__mod_term_func` (the layout Apple's toolchain produces for the official build). The resulting undefined-symbol set matches the official 2.7.2 binary.

The kext in `EFI/OC/Kexts/BlueToolFixup.kext` is the output of this procedure on the author's machine.
