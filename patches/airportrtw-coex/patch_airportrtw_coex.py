#!/usr/bin/env python3
"""Let AirportRTW share the antenna with Bluetooth (rtw89 BTC_MODE_NORMAL).

AirportRTW V2.1.0 (Sequoia build, source commit 4728ceca) calls
rtw88_force_wifi_only() unconditionally from Rtw89LinuxBridge.cpp, which puts
the rtw89 coex engine into BTC_MODE_WL (antenna always granted to WLAN).
With a working Bluetooth driver for the BT half of the combo card this starves
Bluetooth: scans return zero devices while Wi-Fi is on.

This patch turns the first instruction of _rtw88_force_wifi_only into `ret`,
so the flag is never set and rtw89_core_start() falls back to BTC_MODE_NORMAL,
the same mode Linux uses.

Usage: python3 patch_airportrtw_coex.py path/to/AirportRTW.kext/Contents/MacOS/AirportRTW
"""
import hashlib
import sys

ORIGINAL_SHA256 = "bccd617bf875c6ec0d8a87f7c173abbc1c6071bbb9bdc89e5d21a3a8549a1be7"
PATCHED_SHA256 = "1605cffadc2d1f634a43b3549414923d44f14a8f7ae0073d592b944ccb379ed0"
OFFSET = 0x14C130  # _rtw88_force_wifi_only (rtw89 variant), push %rbp -> ret

path = sys.argv[1]
data = bytearray(open(path, "rb").read())
digest = hashlib.sha256(data).hexdigest()
if digest == PATCHED_SHA256:
    sys.exit("already patched")
if digest != ORIGINAL_SHA256:
    sys.exit("unexpected AirportRTW binary (sha256 %s); only the V2.1.0 Sequoia release is supported" % digest)
assert data[OFFSET] == 0x55
data[OFFSET] = 0xC3
assert hashlib.sha256(data).hexdigest() == PATCHED_SHA256
open(path, "wb").write(data)
print("patched:", path)
