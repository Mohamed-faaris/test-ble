# Android release and device helper scripts

Ubuntu / zsh friendly helpers for a Capacitor Android project.

## Prerequisites

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk adb apksigner
```

Install Android SDK Platform Tools and accept SDK licenses. Set `ANDROID_HOME` and include `platform-tools` in PATH.

## Layout

Place this directory in the repository root:

```
project/
├── android/
│   ├── gradlew
│   └── app/
├── scripts/
└── output/  # generated and ignored
```

## Create signing key

```bash
chmod +x scripts/*.sh
./scripts/create-keys.sh
```

Creates `keystore/release.keystore` and `android/keystore.properties`. Both are private and ignored by Git. Back them up securely. Losing the key can prevent signed updates to an already-published app.

## Configure Gradle signing

```bash
./scripts/setup-signing-gradle.sh
```

The helper prints a Groovy DSL example and detects the app Gradle file. Merge it manually into the existing `android {}` block. For Kotlin DSL (`build.gradle.kts`), translate the snippet rather than pasting Groovy syntax.

## Build release

```bash
./scripts/build-release.sh
```

Builds frontend assets (pnpm when a pnpm lockfile exists, otherwise npm), runs Capacitor sync when available, builds the release APK, and collects release APK/AAB outputs under:

```
output/YYYYMMDD-HHMMSS-test-ble.app/
```

All build outputs are copied, not moved. Set `APP_NAME=my-app`, `GRADLE_MODULE=:mobile`, `ANDROID_DIR=/path/to/android`, or `SKIP_WEB_SYNC=1` to customize behavior.

## Connect and install

```bash
./scripts/connect.sh
./scripts/install.sh
```

Install a specific APK:

```bash
./scripts/install.sh path/to/app-release.apk
```

Select a device:

```bash
adb devices -l
export ANDROID_SERIAL=<serial>
./scripts/install.sh
```

Wireless debugging (Android 11+):

```bash
adb pair PHONE_IP:PAIRING_PORT
adb connect PHONE_IP:CONNECT_PORT
```

USB-to-TCPIP helper:

```bash
./scripts/connect.sh --tcpip <phone-ip>
adb connect <phone-ip>:5555
```

Release artifacts are not committed to Git.
