#!/usr/bin/env sh
set -eu

CONF_FILE="/etc/ota-updater.conf"

if [ ! -f "${CONF_FILE}" ]; then
  echo "ota-updater: missing ${CONF_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "${CONF_FILE}"

if [ -z "${MANIFEST_URL:-}" ]; then
  echo "ota-updater: MANIFEST_URL is not set; skipping"
  exit 0
fi

WORK_DIR="${WORK_DIR:-/data/ota}"
MANIFEST_TMP="${WORK_DIR}/latest.manifest"
CURRENT_VERSION_FILE="${WORK_DIR}/current-version"
PENDING_VERSION_FILE="${WORK_DIR}/pending-version"

mkdir -p "${WORK_DIR}"

curl_fetch() {
  if [ -n "${JENKINS_USER:-}" ] && [ -n "${JENKINS_TOKEN:-}" ]; then
    curl -fsSL -u "${JENKINS_USER}:${JENKINS_TOKEN}" "$1" -o "$2"
  else
    curl -fsSL "$1" -o "$2"
  fi
}

# If last update succeeded and we rebooted, promote pending version.
if [ -f "${PENDING_VERSION_FILE}" ]; then
  cp "${PENDING_VERSION_FILE}" "${CURRENT_VERSION_FILE}"
  rm -f "${PENDING_VERSION_FILE}"
fi

curl_fetch "${MANIFEST_URL}" "${MANIFEST_TMP}"

VERSION="$(grep '^VERSION=' "${MANIFEST_TMP}" | head -n1 | cut -d= -f2-)"
BUNDLE_URL="$(grep '^BUNDLE_URL=' "${MANIFEST_TMP}" | head -n1 | cut -d= -f2-)"
SHA256="$(grep '^SHA256=' "${MANIFEST_TMP}" | head -n1 | cut -d= -f2- || true)"

if [ -z "${VERSION}" ] || [ -z "${BUNDLE_URL}" ]; then
  echo "ota-updater: manifest missing VERSION or BUNDLE_URL" >&2
  exit 1
fi

CURRENT_VERSION=""
if [ -f "${CURRENT_VERSION_FILE}" ]; then
  CURRENT_VERSION="$(cat "${CURRENT_VERSION_FILE}")"
fi

if [ "${VERSION}" = "${CURRENT_VERSION}" ]; then
  echo "ota-updater: no new update (version ${VERSION})"
  exit 0
fi

BUNDLE_FILE="${WORK_DIR}/update-${VERSION}.raucb"

curl_fetch "${BUNDLE_URL}" "${BUNDLE_FILE}"

if [ -n "${SHA256}" ]; then
  echo "${SHA256}  ${BUNDLE_FILE}" | sha256sum -c -
fi

rauc install "${BUNDLE_FILE}"
echo "${VERSION}" > "${PENDING_VERSION_FILE}"

if [ "${AUTO_REBOOT:-false}" = "true" ]; then
  systemctl reboot
else
  echo "ota-updater: update installed (version ${VERSION}), reboot required"
fi
