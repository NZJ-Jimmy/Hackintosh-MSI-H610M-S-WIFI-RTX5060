# Component sources

| Component | Version | Source | License |
|---|---|---|---|
| OpenCore (OpenCore.efi, BOOTx64.efi, drivers, OpenShell) | 1.0.8 | https://github.com/acidanthera/OpenCorePkg/releases/tag/1.0.8 | BSD-3-Clause |
| Lilu | 1.7.2 | https://github.com/acidanthera/Lilu/releases/tag/1.7.2 | BSD-3-Clause |
| VirtualSMC | 1.3.8 | https://github.com/acidanthera/VirtualSMC/releases/tag/1.3.8 | BSD-3-Clause |
| AppleALC | 1.9.8 | https://github.com/acidanthera/AppleALC/releases/tag/1.9.8 | BSD-3-Clause |
| NVMeFix | 1.1.3 | https://github.com/acidanthera/NVMeFix/releases/tag/1.1.3 | BSD-3-Clause |
| RestrictEvents | 1.1.7 | https://github.com/acidanthera/RestrictEvents | BSD-3-Clause |
| CpuTopologyRebuild (disabled) | 2.0.2 | https://github.com/b00t0x/CpuTopologyRebuild | see license file |
| RealtekRTL8111 | 3.0.0 | https://github.com/Mieze/RTL8111_driver_for_OS_X | GPL-2.0 |
| AMFIPass | 1.4.1 | OpenCore-Legacy-Patcher `payloads/Kexts/Acidanthera/AMFIPass-v1.4.1-RELEASE.zip` | OCLP license |
| AirportRTW (**patched**, see `patches/airportrtw-coex`) | V2.1.0 Sequoia build, source commit 4728ceca | https://github.com/souissiak1-maker/AirportRTW | GPL-2.0 |
| RealtekBluetoothFirmware (**patched**, see `patches/realtek-bt-dongle-mode`) | 1.0.2 | https://github.com/thegwchr/RealtekBluetoothFirmware | GPL-2.0-or-later |
| BlueToolFixup (**rebuilt with patches**, see `patches/bluetoothd-setEventMaskPage2`) | 2.7.2 | https://github.com/acidanthera/BrcmPatchRAM/tree/2.7.2 | GPL-2.0 |
| NullMothSafe.efi | from NullMoth 1401 app 1.15.0 | https://github.com/nullmoth/nvidia-macos-driver | PolyForm Noncommercial 1.0.0 |
| USBToolBox | 1.2.0 | **not redistributed** — `fetch-usbtoolbox.sh` downloads it | no open-source license |
| UTBMap.kext, SSDT-*.aml | — | generated for this board (ASL sources in `ACPI-src/`) | MIT (this repo) |

Patched binaries: the corresponding source is the upstream source at the listed version plus the changes described in `patches/` (byte patches with SHA256-checked scripts, and a source diff for BlueToolFixup).
