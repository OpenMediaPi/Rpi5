#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$1"

# Ensure directories expected by RAUC exist.
mkdir -p "${TARGET_DIR}/run/rauc"
mkdir -p "${TARGET_DIR}/data"

# Enable periodic OTA checks.
mkdir -p "${TARGET_DIR}/etc/systemd/system/timers.target.wants"
ln -sf /usr/lib/systemd/system/ota-updater.timer \
  "${TARGET_DIR}/etc/systemd/system/timers.target.wants/ota-updater.timer"
