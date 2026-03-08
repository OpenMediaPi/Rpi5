#!/usr/bin/env bash
set -euo pipefail

BUILDROOT_VERSION="${BUILDROOT_VERSION:-2025.02}"
BUILDROOT_DIR="${1:-buildroot}"

if [ -d "${BUILDROOT_DIR}/.git" ]; then
  echo "buildroot already present at ${BUILDROOT_DIR}"
  exit 0
fi

git clone --branch "${BUILDROOT_VERSION}" --depth 1 https://github.com/buildroot/buildroot.git "${BUILDROOT_DIR}"
echo "cloned buildroot ${BUILDROOT_VERSION} into ${BUILDROOT_DIR}"
