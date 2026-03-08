#!/usr/bin/env bash
set -euo pipefail

BUILDROOT_DIR="${1:-buildroot}"
OUT_DIR="${2:-output/rpi5_kodi_ota}"
JOBS="${JOBS:-$(nproc)}"
CLEAN_OUTPUT="${CLEAN_OUTPUT:-true}"

if [ ! -d "${BUILDROOT_DIR}" ]; then
  echo "missing ${BUILDROOT_DIR}; run scripts/init-buildroot.sh first"
  exit 1
fi

if [ "${CLEAN_OUTPUT}" = "true" ]; then
  rm -rf "${OUT_DIR}"
fi

mkdir -p "${OUT_DIR}"
rm -f "${OUT_DIR}/.config"

make -C "${BUILDROOT_DIR}" BR2_EXTERNAL="$(pwd)/buildroot-external" O="$(pwd)/${OUT_DIR}" rpi5_kodi_ota_defconfig
make -C "${BUILDROOT_DIR}" O="$(pwd)/${OUT_DIR}" -j"${JOBS}"

echo "image ready at ${OUT_DIR}/images/rpi5-kodi-ota.img"
