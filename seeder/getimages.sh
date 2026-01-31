#!/bin/bash
# stage: Image aquisition
UBUNTU_NOBLE_URL=https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
UBUNTU_NOBLE_CHECKSUM=$(curl -s https://cloud-images.ubuntu.com/noble/current/SHA256SUMS | grep noble-server-cloudimg-amd64.img | awk -F' ' '{print $1}')
UBUNTU_JAMMY_URL=https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
UBUNTU_JAMMY_CHECKSUM=$(curl -s https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS | grep jammy-server-cloudimg-amd64.img | awk -F' ' '{print $1}')
DEBIAN_TRIXIE_URL=https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2
DEBIAN_TRIXIE_CHECKSUM=$(curl -s https://cdimage.debian.org/images/cloud/trixie/latest/SHA512SUMS | grep debian-13-genericcloud-amd64.qcow2 | awk -F' ' '{print $1}')
ALPINE_3_23_2_URL=https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/cloud/generic_alpine-3.23.2-x86_64-bios-tiny-r0.qcow2


echo "Checking Ubuntu Jammy"
test -f "jammy-server-cloudimg-amd64.img" && echo "Ubuntu Jammy image already exists... Skipping download." || { echo "Downloading Ubuntu Jammy..."; wget -q --show-progress $UBUNTU_JAMMY_URL; }
echo Checking integrity...
echo "$UBUNTU_JAMMY_CHECKSUM jammy-server-cloudimg-amd64.img" | sha256sum -c --status && echo "✅ Integrity verified !" || echo "/❗\ WARNING /❗\ : ❌ File integrity altered ! USE WITH CAUTION"
echo $UBUNTU_JAMMY_CHECKSUM > jammy-server-cloudimg-amd64.img.sha256
chmod 444 jammy-server-cloudimg-amd64.img

echo "Checking Ubuntu Noble"
test -f "noble-server-cloudimg-amd64.img" && echo "Ubuntu Noble image already exists... Skipping download." || { echo "Downloading Ubuntu Noble..."; wget -q --show-progress $UBUNTU_NOBLE_URL; }
echo Checking integrity...
echo "$UBUNTU_NOBLE_CHECKSUM noble-server-cloudimg-amd64.img" | sha256sum -c --status && echo "✅ Integrity verified !" || echo "/❗\ WARNING /❗\ : ❌ File integrity altered ! USE WITH CAUTION"
echo $UBUNTU_NOBLE_CHECKSUM > noble-server-cloudimg-amd64.img.sha256
chmod 444 noble-server-cloudimg-amd64.img

echo "Checking Debian Trixie"
test -f "debian-13-genericcloud-amd64.qcow2" && echo "Debian Trixie image already exists... Skipping download." || { echo "Downloading Debian Trixie..."; wget -q --show-progress $DEBIAN_TRIXIE_URL; }
echo Checking integrity...
echo "$DEBIAN_TRIXIE_CHECKSUM debian-13-genericcloud-amd64.qcow2" | sha512sum -c --status && echo "✅ Integrity verified !" || echo "/❗\ WARNING /❗\ : ❌ File integrity altered ! USE WITH CAUTION"
echo $DEBIAN_TRIXIE_CHECKSUM > debian-13-genericcloud-amd64.qcow2.sha512
chmod 444 debian-13-genericcloud-amd64.qcow2

echo "Checking Alpine 3.23.2"
test -f "generic_alpine-3.23.2-x86_64-bios-tiny-r0.qcow2" && echo "Alpine 3.23.2 already exists... Skipping download." || { echo "Downloading Alpine 3.23.2..."; wget -q --show-progress $ALPINE_3_23_2_URL; }
echo WARNING: No integrity check implemented...
chmod 444 generic_alpine-3.23.2-x86_64-bios-tiny-r0.qcow2