#!/usr/bin/env bash
set -euo pipefail

if command -v make >/dev/null 2>&1; then
  echo "build deps: make already available"
  exit 0
fi

echo "build deps: make not found, attempting to install prerequisites"

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends \
    build-essential git rsync bc bison flex perl python3 \
    cpio unzip file wget xz-utils gzip bzip2 patch ca-certificates
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y \
    make gcc gcc-c++ git rsync bc bison flex perl python3 \
    cpio unzip file wget xz gzip bzip2 patch ca-certificates
elif command -v yum >/dev/null 2>&1; then
  yum install -y \
    make gcc gcc-c++ git rsync bc bison flex perl python3 \
    cpio unzip file wget xz gzip bzip2 patch ca-certificates
elif command -v apk >/dev/null 2>&1; then
  apk add --no-cache \
    build-base git rsync bc bison flex perl python3 \
    cpio unzip file wget xz gzip bzip2 patch ca-certificates
else
  echo "Unsupported package manager; install Buildroot host deps manually on this Jenkins agent." >&2
  exit 1
fi

if ! command -v make >/dev/null 2>&1; then
  echo "Dependency install finished, but make is still unavailable." >&2
  exit 1
fi

echo "build deps: prerequisites installed"
