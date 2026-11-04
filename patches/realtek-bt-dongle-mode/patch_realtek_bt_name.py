#!/usr/bin/env python3
"""Make bluetoothd treat the Realtek controller as a third-party USB dongle.

RealtekBluetoothFirmware 1.0.2 renames the USB device to
"Bluetooth USB Host Controller" after uploading firmware. bluetoothd then
treats it as Apple's internal controller, defaults the chipset to BCM_4350C2
and sends Broadcom vendor commands, which fail and put Bluetooth into a
restart loop ("turns on, then off").

This patch replaces that string with a same-length name, so the device keeps
class 0xE0/1/1 but is no longer mistaken for the internal controller.
bluetoothd then logs "Found external Bluetooth dongle -- setting chipset to
THIRD_PARTY_DONGLE". Also set NVRAM bluetoothHostControllerSwitchBehavior=always
(already in config.plist).

Usage: python3 patch_realtek_bt_name.py path/to/RealtekBluetoothFirmware.kext/Contents/MacOS/RealtekBluetoothFirmware
"""
import hashlib
import sys

ORIGINAL_SHA256 = "9599f9a77fd64e8f1a5511228275fe17c44eba9cbf0f55c82c3ddc7cc7b27987"
PATCHED_SHA256 = "8e45de7af15ebf94fa10b71ecdbd13a556a80f9b30b62acad00dea64c8ad2e60"
OLD = b"Bluetooth USB Host Controller\0"
NEW = b"Realtek USB Bluetooth Adapter\0"

path = sys.argv[1]
data = open(path, "rb").read()
digest = hashlib.sha256(data).hexdigest()
if digest == PATCHED_SHA256:
    sys.exit("already patched")
if digest != ORIGINAL_SHA256:
    sys.exit("unexpected RealtekBluetoothFirmware binary (sha256 %s); only v1.0.2 release is supported" % digest)
assert len(OLD) == len(NEW) and data.count(OLD) == 1
data = data.replace(OLD, NEW)
assert hashlib.sha256(data).hexdigest() == PATCHED_SHA256
open(path, "wb").write(data)
print("patched:", path)
