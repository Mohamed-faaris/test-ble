#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ANDROID_DIR="$(find_android_dir)"
APP_GRADLE=""
for candidate in "$ANDROID_DIR/app/build.gradle" "$ANDROID_DIR/app/build.gradle.kts"; do
  [[ -f "$candidate" ]] && APP_GRADLE="$candidate" && break
done
[[ -n "$APP_GRADLE" ]] || die "Cannot find app/build.gradle or app/build.gradle.kts"

cat <<'MSG'
Merge this Groovy DSL configuration into the existing app build.gradle.
Do not paste Groovy into build.gradle.kts; translate it to Kotlin DSL.
This helper intentionally does not rewrite Gradle files automatically.
MSG
cat <<'GRADLE'

// Load credentials from android/keystore.properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
GRADLE
printf '\\nDetected Gradle file: %s\\n' "$APP_GRADLE"
