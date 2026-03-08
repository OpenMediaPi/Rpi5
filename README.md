# RPi5 Buildroot Template: Kodi + OTA (RAUC)

This repository now contains a starter `br2-external` template for Raspberry Pi 5 that targets:

- Buildroot-based image
- Kodi as the media UI
- A/B root filesystem layout for OTA updates using RAUC

It is a starting point, not a production-finished distro.

## Layout

- `buildroot-external/configs/rpi5_kodi_ota_defconfig`: baseline Buildroot config
- `buildroot-external/board/rpi5-kodi-ota/`: board boot files, genimage layout, hooks, overlays
- `scripts/init-buildroot.sh`: clone Buildroot (default: `2025.02`)
- `scripts/build.sh`: build image
- `scripts/mk-ota-bundle.sh`: create signed RAUC bundle from built rootfs
- `scripts/ensure-build-deps.sh`: install host dependencies on CI agent (best effort)
- `Jenkinsfile`: CI pipeline for Jenkins

## Quick Start

1. Clone Buildroot:

```bash
./scripts/init-buildroot.sh
```

2. Build the image:

```bash
./scripts/build.sh
```

3. Flash image:

```bash
sudo dd if=output/rpi5_kodi_ota/images/rpi5-kodi-ota.img of=/dev/sdX bs=4M conv=fsync status=progress
```

## OTA Bundle Flow

1. Create signing material (example):

```bash
mkdir -p keys
openssl req -x509 -newkey rsa:4096 -nodes -keyout keys/rauc-key.pem -out keys/rauc-cert.pem -subj "/CN=rpi5-kodi-ota" -days 3650
cp keys/rauc-cert.pem buildroot-external/board/rpi5-kodi-ota/overlay/etc/rauc/keyring.pem
```

2. Rebuild image so keyring lands in rootfs.

3. Create bundle:

```bash
./scripts/mk-ota-bundle.sh
```

4. On target, install bundle:

```bash
rauc install /path/to/update.raucb
reboot
```

## Auto Updates From Jenkins

Devices can poll Jenkins artifacts directly using the included systemd timer:

- `ota-updater.timer` runs every 30 minutes
- `ota-updater.service` runs `/usr/bin/ota-updater.sh`
- config file: `/etc/ota-updater.conf`

Jenkins publishes `latest.manifest` on OTA builds with:

- `VERSION`
- `BUNDLE_URL`
- `SHA256`

Set on target in `/etc/ota-updater.conf`:

```sh
MANIFEST_URL="https://<jenkins>/job/<folder>/job/<pipeline>/lastSuccessfulBuild/artifact/output/rpi5_kodi_ota/images/latest.manifest"
JENKINS_USER="your-user"      # optional
JENKINS_TOKEN="your-api-token" # optional
AUTO_REBOOT="false"
```

If Jenkins artifact access is public, leave `JENKINS_USER` and `JENKINS_TOKEN` empty.

## Jenkins

This repo includes a ready `Jenkinsfile`.

1. Create a Jenkins Pipeline job pointing to this repository.
2. Run with defaults for image build, or set:
   - `MAKE_OTA_BUNDLE=true` to also build `update.raucb`
   - `BUILDROOT_VERSION` to pin another Buildroot tag/branch
   - `JOBS` to match your Jenkins agent CPU
   - `AUTO_INSTALL_BUILD_DEPS=true` to auto-install missing tools like `make`
3. If OTA bundle is enabled, create Jenkins **Secret file** credentials:
   - cert PEM credential ID (default: `rauc-cert-pem`)
   - key PEM credential ID (default: `rauc-key-pem`)
4. Optionally override:
   - `RAUC_CERT_CRED_ID`
   - `RAUC_KEY_CRED_ID`

Build artifacts are archived from `${OUT_DIR}/images/`.
When OTA is enabled, Jenkins also creates:

- `update-<build>-<commit>.raucb`
- `latest.manifest`

## Important Notes

- `cmdline.txt` currently boots slot A (`/dev/mmcblk0p2`) by default.
- Full boot-slot switching logic is not yet implemented. Add custom bootloader logic for robust A/B failover.
- The defconfig is intentionally compact and may require package/kernel tuning for your exact Kodi pipeline.
- For production OTA, add:
  - rollback strategy
  - health checks
  - signed key rotation process
  - remote update client/service
