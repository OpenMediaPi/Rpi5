#!/usr/bin/env bash
set -euo pipefail

BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"

rm -rf "${BINARIES_DIR}/genimage.tmp"
mkdir -p "${BINARIES_DIR}/genimage.tmp"

genimage \
  --rootpath "${TARGET_DIR}" \
  --tmppath "${BINARIES_DIR}/genimage.tmp" \
  --inputpath "${BINARIES_DIR}" \
  --outputpath "${BINARIES_DIR}" \
  --config "${GENIMAGE_CFG}"
