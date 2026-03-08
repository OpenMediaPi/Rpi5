pipeline {
  agent any

  options {
    timestamps()
  }

  parameters {
    string(name: 'BUILDROOT_VERSION', defaultValue: '2025.02', description: 'Buildroot tag/branch')
    string(name: 'BUILDROOT_DIR', defaultValue: 'buildroot', description: 'Buildroot checkout directory')
    string(name: 'OUT_DIR', defaultValue: 'output/rpi5_kodi_ota', description: 'Build output directory')
    string(name: 'JOBS', defaultValue: '8', description: 'Parallel make jobs')
    booleanParam(name: 'CLEAN_OUTPUT', defaultValue: true, description: 'Delete output directory before configuring/building')
    booleanParam(name: 'AUTO_INSTALL_BUILD_DEPS', defaultValue: true, description: 'Attempt to install missing host build tools on agent')
    booleanParam(name: 'MAKE_OTA_BUNDLE', defaultValue: false, description: 'Build RAUC bundle after image build')
    string(name: 'RAUC_CERT_CRED_ID', defaultValue: 'rauc-cert-pem', description: 'Jenkins Secret file credential ID for RAUC cert PEM')
    string(name: 'RAUC_KEY_CRED_ID', defaultValue: 'rauc-key-pem', description: 'Jenkins Secret file credential ID for RAUC key PEM')
  }

  environment {
    BUILDROOT_VERSION = "${params.BUILDROOT_VERSION}"
    JOBS = "${params.JOBS}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Init Buildroot') {
      steps {
        script {
          if (params.AUTO_INSTALL_BUILD_DEPS) {
            sh '''
              set -eux
              if [ "$(id -u)" -eq 0 ]; then
                ./scripts/ensure-build-deps.sh
              else
                if command -v sudo >/dev/null 2>&1; then
                  sudo ./scripts/ensure-build-deps.sh
                else
                  echo "AUTO_INSTALL_BUILD_DEPS is true, but agent is non-root and sudo is missing." >&2
                  echo "Install build deps on the node manually or run agent as root." >&2
                  exit 1
                fi
              fi
            '''
          }
        }
        withEnv(["BUILDROOT_DIR=${params.BUILDROOT_DIR}"]) {
          sh '''
            set -eux
            ./scripts/init-buildroot.sh "${BUILDROOT_DIR}"
          '''
        }
      }
    }

    stage('Build Image') {
      steps {
        withEnv([
          "BUILDROOT_DIR=${params.BUILDROOT_DIR}",
          "OUT_DIR=${params.OUT_DIR}",
          "CLEAN_OUTPUT=${params.CLEAN_OUTPUT}"
        ]) {
          sh '''
            set -eux
            ./scripts/build.sh "${BUILDROOT_DIR}" "${OUT_DIR}"
          '''
        }
      }
    }

    stage('Build OTA Bundle') {
      when {
        expression { return params.MAKE_OTA_BUNDLE }
      }
      steps {
        script {
          def jobPath = env.JOB_NAME.tokenize('/').collect { "job/${it}" }.join('/')
          env.ARTIFACT_BASE_URL = "${env.JENKINS_URL}${jobPath}/${env.BUILD_NUMBER}/artifact/${params.OUT_DIR}/images"
        }
        withCredentials([
          file(credentialsId: "${params.RAUC_CERT_CRED_ID}", variable: 'RAUC_CERT_FILE'),
          file(credentialsId: "${params.RAUC_KEY_CRED_ID}", variable: 'RAUC_KEY_FILE')
        ]) {
          withEnv(["OUT_DIR=${params.OUT_DIR}"]) {
            sh '''
              set -eux
              ./scripts/mk-ota-bundle.sh "${OUT_DIR}" "${RAUC_CERT_FILE}" "${RAUC_KEY_FILE}"

              SHORT_COMMIT="$(printf '%s' "${GIT_COMMIT:-unknown}" | cut -c1-8)"
              OTA_VERSION="${BUILD_NUMBER}-${SHORT_COMMIT}"
              VERSIONED_BUNDLE="update-${OTA_VERSION}.raucb"
              cp "${OUT_DIR}/images/update.raucb" "${OUT_DIR}/images/${VERSIONED_BUNDLE}"

              SHA256="$(sha256sum "${OUT_DIR}/images/${VERSIONED_BUNDLE}" | awk '{print $1}')"
              cat > "${OUT_DIR}/images/latest.manifest" <<MANIFEST
VERSION=${OTA_VERSION}
BUNDLE_URL=${ARTIFACT_BASE_URL}/${VERSIONED_BUNDLE}
SHA256=${SHA256}
MANIFEST
            '''
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: "${params.OUT_DIR}/images/*", allowEmptyArchive: true, fingerprint: true
    }
  }
}
