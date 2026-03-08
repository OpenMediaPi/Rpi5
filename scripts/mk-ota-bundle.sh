#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-output/rpi5_kodi_ota}"
CERT="${2:-keys/rauc-cert.pem}"
KEY="${3:-keys/rauc-key.pem}"

MANIFEST_DIR="${OUT_DIR}/ota"
BUNDLE="${OUT_DIR}/images/update.raucb"
ROOTFS_IMAGE="${OUT_DIR}/images/rootfs.ext4"

mkdir -p "${MANIFEST_DIR}"

cat > "${MANIFEST_DIR}/manifest.raucm" <<MANIFEST
[update]
compatible=rpi5-kodi
version=$(date +%Y%m%d%H%M)

[bundle]
format=verity

[image.rootfs]
filename=rootfs.ext4
MANIFEST

cp "${ROOTFS_IMAGE}" "${MANIFEST_DIR}/rootfs.ext4"
rauc bundle --cert "${CERT}" --key "${KEY}" "${MANIFEST_DIR}" "${BUNDLE}"

echo "bundle generated: ${BUNDLE}"
