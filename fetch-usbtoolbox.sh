#!/bin/sh
# USBToolBox has no open-source license ("All rights reserved"), so it is not
# redistributed here. This script downloads the official 1.2.0 release,
# verifies its SHA256 and places USBToolBox.kext into EFI/OC/Kexts.
set -eu
cd "$(dirname "$0")"
URL=https://github.com/USBToolBox/kext/releases/download/1.2.0/USBToolBox-1.2.0-RELEASE.zip
SHA=c315a3a5acfd496dd97d0d19b4fbd1d487103d2fd541c5651583d4c9cebcfe07
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/utb.zip" "$URL"
if command -v sha256sum >/dev/null; then GOT=$(sha256sum "$TMP/utb.zip" | cut -d' ' -f1); else GOT=$(shasum -a 256 "$TMP/utb.zip" | cut -d' ' -f1); fi
[ "$GOT" = "$SHA" ] || { echo "SHA256 mismatch: $GOT"; exit 1; }
unzip -q "$TMP/utb.zip" -d "$TMP/x"
rm -rf EFI/OC/Kexts/USBToolBox.kext
cp -R "$TMP/x/USBToolBox.kext" EFI/OC/Kexts/
echo "USBToolBox.kext 1.2.0 installed into EFI/OC/Kexts"
