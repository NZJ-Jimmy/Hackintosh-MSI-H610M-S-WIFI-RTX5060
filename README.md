# MSI PRO H610M-S WIFI · i5-14400F · RTX 5060 — macOS Sequoia (OpenCore EFI)

一套实机可用的 OpenCore EFI：NVIDIA RTX 5060 硬件加速（NullMoth 驱动）、原生 Wi-Fi 菜单（AirportRTW）、Realtek 蓝牙（RTL8852CE 组合卡），以及让 Wi-Fi 与蓝牙同时工作所需的三个补丁。

A working OpenCore EFI for an MSI PRO H610M-S WIFI DDR4 + i5-14400F + RTX 5060 running macOS Sequoia 15.8.1, including RTX 5060 acceleration (NullMoth driver), native Wi-Fi menu (AirportRTW) and Realtek RTL8852CE Bluetooth working **at the same time as Wi-Fi**. English summary at the end.

> ⚠️ `config.plist` 中的 SMBIOS（序列号 / MLB / UUID / ROM）已替换为占位值，使用前请用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 为 `MacPro7,1` 生成你自己的。

## 硬件

| 项目 | 型号 |
|---|---|
| 主板 | MSI PRO H610M-S WIFI DDR4（MS-7E44，BIOS 1.60） |
| CPU | Intel i5-14400F（无核显） |
| 显卡 | MSI RTX 5060（GB206, 10de:2d05） |
| 声卡 | Realtek ALC897（`alcid=11`） |
| 有线 | Realtek RTL8111 |
| 无线 | Realtek RTL8852CE（Wi-Fi 10ec:c852 / 蓝牙 USB 13d3:3586） |
| SMBIOS | MacPro7,1 |
| 系统 | macOS 15.8.1 (24H32)，OpenCore 1.0.8 |

## 工作状态

| 功能 | 状态 |
|---|---|
| RTX 5060 显示与 Metal 加速 | ✅（NullMoth 驱动，需在 macOS 内另行安装） |
| 高刷新率 | ⚠️ 165 Hz 可用；切换刷新率可能闪屏，200 Hz 黑屏（上游已知问题） |
| 睡眠唤醒 | ❌ 唤醒后无信号 / NVRMFB 超时 panic（上游已知），建议关闭自动睡眠 |
| HDMI/DP 音频 | ❌（NullMoth 当前不支持） |
| 有线网络 | ✅ |
| Wi-Fi（系统原生菜单） | ✅ AirportRTW（打了共存补丁） |
| 蓝牙（扫描、配对） | ✅ 与 Wi-Fi 同时可用（三个补丁，见下） |
| AirDrop / 接力 / 通用剪贴板 | ❌ 需要 AWDL，第三方 Wi-Fi 驱动都不支持；需要换博通网卡 |

## 这套 EFI 的特别之处：RTL8852CE 蓝牙 + Wi-Fi 共存

RTL8852CE 的蓝牙在 Sequoia 上一开始“打开后又自动关闭”，排查下来是三层问题，逐层修复：

1. **被当成 Mac 内置 Broadcom 芯片** —— RealtekBluetoothFirmware 上传固件后把设备改名为 `Bluetooth USB Host Controller`，bluetoothd 于是按 `BCM_4350C2` 初始化并失败。
   修复：把该字符串改成同长度的 `Realtek USB Bluetooth Adapter`，并设置 NVRAM `bluetoothHostControllerSwitchBehavior=always`。→ [`patches/realtek-bt-dongle-mode`](patches/realtek-bt-dongle-mode)
2. **HCI 初始化被 bluetoothd 中止** —— `OI_HCICMD_SetEventMaskPage2 returned STATUS 46`。
   修复：重新编译 BlueToolFixup 2.7.2，在内存中给 bluetoothd 打三处补丁（来自 [RealtekBluetoothFirmware#6](https://github.com/thegwchr/RealtekBluetoothFirmware/issues/6)，已核对适用于 15.8.1）。→ [`patches/bluetoothd-setEventMaskPage2`](patches/bluetoothd-setEventMaskPage2)
3. **Wi-Fi 开着时扫描不到任何设备** —— AirportRTW 启动时无条件调用 `rtw88_force_wifi_only()`，把 rtw89 共存设为 `BTC_MODE_WL`（天线始终给 Wi-Fi）。
   修复：1 字节补丁让它回到 Linux 默认的 `BTC_MODE_NORMAL`。→ [`patches/airportrtw-coex`](patches/airportrtw-coex)

`EFI/OC/Kexts` 里的这三个 kext 已经是打过补丁的版本；`patches/` 目录提供可复现的脚本（带 SHA256 校验）和源码 diff。

## 使用步骤

1. **准备组件**：运行 `sh fetch-usbtoolbox.sh`（USBToolBox 没有开源许可证，不随仓库分发，脚本从官方 1.2.0 发行页下载并校验）。
2. **SMBIOS**：在 `config.plist → PlatformInfo → Generic` 填入你自己生成的 `SystemSerialNumber`、`MLB`、`SystemUUID`、`ROM`。
3. **USB 映射**：`UTBMap.kext` 是本机（MS-7E44）的映射，其他主板需要自己用 USBToolBox 重做。蓝牙在内部端口 HS14（UsbConnector 255）。
4. **NVIDIA 驱动**：从 [nullmoth/nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver) 下载并在 macOS 内安装（不要从 EFI 注入其 kext）。安装阶段可先用固件显示，驱动装好后再屏蔽 `IONDRVSupport`（本 config 已屏蔽）。
5. 复制 `EFI` 到 ESP。

### 重要的启动参数

```
-v keepsyms=1 debug=0x100 alcid=11
nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth -nvrmnoflip         # NullMoth NVIDIA
amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0  # 让 WindowServer 加载 NVIDIA bundle
-btlfxallowanyaddr -amfipassbeta
```

`csr-active-config` = `430A0000`，`SecureBootModel` = `Disabled`。

## 踩过的坑

- **显卡突然没有加速**：检查启动参数里是否有 **`-nvoff`**。NullMoth 的 1401 应用在“准备系统更新”时会加上它来停用驱动，更新完成步骤没跑完就会一直留着。
- **不要停用 AMFIPass**：新版 NullMoth 驱动需要它（由 1401 应用自动加入）。
- **改刷新率后黑屏只剩鼠标**：在恢复模式删除 `/Library/Preferences/com.apple.windowserver*.plist` 及用户 `ByHost` 下的同名文件。
- 升级 macOS 后 bluetoothd 可能变化，补丁不再匹配，蓝牙会回到“开了又关”；更新 AirportRTW / RealtekBluetoothFirmware 后需重新应用补丁。

## 致谢与许可

OpenCore / Lilu / VirtualSMC / AppleALC / NVMeFix / RestrictEvents / BlueToolFixup（acidanthera）、AMFIPass（dhinakg，经 OCLP 分发）、CpuTopologyRebuild（b00t0x）、RealtekRTL8111、AirportRTW（souissiak1-maker）、RealtekBluetoothFirmware（thegwchr）、NullMoth NVIDIA driver（nullmoth，PolyForm Noncommercial 1.0.0，仅 `NullMothSafe.efi` 随附）、USBToolBox（Dhinak G）。

各组件许可证见 [`Licenses/`](Licenses)。AirportRTW、RealtekBluetoothFirmware 与 BlueToolFixup 为 GPL 软件，本仓库中的修改版二进制对应的源码为上游源码加上 `patches/` 中描述的改动。本仓库自有的脚本与文档以 MIT 许可发布（见 `LICENSE`）。

本仓库仅供学习交流。黑苹果可能违反 Apple 的软件许可协议，请自行评估。

---

## English summary

Working: RTX 5060 Metal acceleration (NullMoth), Ethernet, Wi-Fi via AirportRTW native frontend, and Realtek RTL8852CE Bluetooth (scan/pair) **while Wi-Fi is on**. Not working: sleep/wake (NullMoth NVRMFB timeout), HDMI/DP audio, AirDrop/Continuity (no AWDL in any third-party Wi-Fi kext).

Bluetooth needed three fixes, each in `patches/` with SHA256-checked scripts:

1. RealtekBluetoothFirmware renames the device to `Bluetooth USB Host Controller`, so bluetoothd treats it as an internal BCM_4350C2 → renamed string + `bluetoothHostControllerSwitchBehavior=always` → `THIRD_PARTY_DONGLE`.
2. bluetoothd aborts on `SetEventMaskPage2 STATUS 46` → rebuilt BlueToolFixup 2.7.2 with the in-memory bluetoothd patches from RealtekBluetoothFirmware#6 (verified on 15.8.1 24H32).
3. AirportRTW forces rtw89 coex into `BTC_MODE_WL` (antenna always to WLAN), so BT scans return nothing while Wi-Fi is on → 1-byte patch to restore `BTC_MODE_NORMAL`.

SMBIOS values in `config.plist` are placeholders — generate your own. Run `fetch-usbtoolbox.sh` first (USBToolBox is not redistributed).
