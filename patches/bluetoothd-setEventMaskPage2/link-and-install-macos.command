#!/bin/bash
# 在 macOS 上把预编译好的目标文件链接成 BlueToolFixup.kext（加入 RTL8852C 的 bluetoothd 补丁），
# 检查无误后替换 ESP-OSX 上的 BlueToolFixup.kext（原版先备份）。
# 需要：Xcode Command Line Tools（xcode-select --install）。不需要 sudo。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ESP="$(cd "$HERE/../.." && pwd)"
KEXTS="$ESP/EFI/OC/Kexts"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/输出-$STAMP"
mkdir -p "$OUT"
exec > >(tee "$OUT/日志.txt") 2>&1

echo "== 1/6 检查 Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1 || ! xcrun -f ld >/dev/null 2>&1; then
  echo "未安装 Command Line Tools。即将弹出安装窗口，装完后重新运行本脚本。未做任何修改。"
  xcode-select --install || true
  exit 1
fi
xcrun ld -v 2>&1 | head -2

echo "== 2/6 检查系统版本与 bluetoothd"
BUILD="$(sw_vers -buildVersion)"; echo "macOS build: $BUILD"
# 运行中的系统读到的 bluetoothd 带有现有 BlueToolFixup 在内存中打的补丁（页缓存），
# 先把这 3 处已知改动还原，再与 Linux 上从磁盘直接读取核对过的原始文件哈希比较。
xcrun python3 - /usr/sbin/bluetoothd <<'PY'
import hashlib, sys
d = bytearray(open(sys.argv[1], 'rb').read())
sites = [(0x1b7a59, bytes.fromhex('81f96f1700007730'), bytes.fromhex('9090909090909090')),
         (0x2ea477, b'\x72', b'\xeb'), (0x320bb3, b'\x72', b'\xeb')]
for off, orig, patched in sites:
    cur = bytes(d[off:off+len(orig)])
    if cur == patched:
        d[off:off+len(orig)] = orig
    elif cur != orig:
        print('停止：0x%x 处内容不符（%s），bluetoothd 可能已更新。未做任何修改。' % (off, cur.hex())); sys.exit(1)
h = hashlib.sha256(d).hexdigest()
print('bluetoothd（还原内存补丁后）sha256:', h)
if h != '8e9aeff1427945ff7a18cf9491fc7dac1286aa738073aa7a81f162b36af510c0':
    print('停止：bluetoothd 与已核对的 15.8.1 (24H32) 版本不同，补丁位置需要重新核对。未做任何修改。'); sys.exit(1)
print('bluetoothd 校验通过')
PY

echo "== 3/6 校验文件"
( cd "$HERE" && shasum -a 256 -c SHA256SUMS )

echo "== 4/6 链接"
K="$OUT/BlueToolFixup.kext"
mkdir -p "$K/Contents/MacOS"
cp "$KEXTS/BlueToolFixup.kext/Contents/Info.plist" "$K/Contents/Info.plist"
xcrun clang -target x86_64-apple-macos10.8 -nostdlib \
  -Xlinker -kext -Xlinker -no_deduplicate \
  -o "$K/Contents/MacOS/BlueToolFixup" \
  "$HERE/plugin_start.o" "$HERE/BlueToolFixup.o" "$HERE/BlueToolFixup_info.o" "$HERE/libkmod.a"

echo "== 5/6 检查产物"
BIN="$K/Contents/MacOS/BlueToolFixup"
otool -hv "$BIN" | tee "$OUT/header.txt"
grep -q KEXTBUNDLE "$OUT/header.txt" || { echo "停止：产物不是 kext 格式。未修改 ESP。"; exit 1; }
nm -u "$BIN" > "$OUT/undefined.txt"
if grep -q -E "^_+(cxa_)?atexit$|^_start$|^_stop$|^_BlueToolFixup_" "$OUT/undefined.txt"; then
  echo "停止：存在不应出现的未定义符号："; grep -E "atexit|_start$|_stop$|_BlueToolFixup_" "$OUT/undefined.txt"; exit 1
fi
grep -q RTLPatchSet "$BIN" || { echo "停止：补丁表缺失。"; exit 1; }
nm "$BIN" | grep -q " D _kmod_info" || { echo "停止：缺少 kmod_info。"; exit 1; }
echo "-- kmutil 依赖检查（仅记录，不作为安装条件）："
kmutil libraries -p "$K" -r "$KEXTS" --undef-symbols > "$OUT/kmutil.txt" 2>&1 || true
cat "$OUT/kmutil.txt"

echo "== 6/6 安装到 ESP（原版先备份）"
mkdir -p "$ESP/EFI/OC/Kexts-backup"
BK="$ESP/EFI/OC/Kexts-backup/BlueToolFixup-original-$STAMP.kext"
cp -R "$KEXTS/BlueToolFixup.kext" "$BK"
cmp "$KEXTS/BlueToolFixup.kext/Contents/MacOS/BlueToolFixup" "$BK/Contents/MacOS/BlueToolFixup"
cp "$BIN" "$KEXTS/BlueToolFixup.kext/Contents/MacOS/BlueToolFixup"
sync
cmp "$BIN" "$KEXTS/BlueToolFixup.kext/Contents/MacOS/BlueToolFixup"
echo
echo "完成：已安装带补丁的 BlueToolFixup。原版备份：$BK"
echo "下一步：关机 → 拔电源约 30 秒 → 开机进 macOS → 测试蓝牙。"
echo "撤回（在 macOS 中）：cp \"$BK/Contents/MacOS/BlueToolFixup\" \"$KEXTS/BlueToolFixup.kext/Contents/MacOS/BlueToolFixup\""
