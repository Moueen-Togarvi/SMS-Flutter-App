# BlueChat

BlueChat is an offline Android Bluetooth Classic messaging app built with Flutter. It discovers nearby devices, connects peer-to-peer over RFCOMM, exchanges newline-delimited JSON packets, and stores all chat history locally with Isar-compatible storage.

## Requirements

- Flutter latest stable
- Android SDK
- JDK 17+
- Two physical Android devices for Bluetooth Classic testing

This repository does not use Firebase, Supabase, PostgreSQL, or any cloud messaging service.

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
```

If the Android project has no `android/local.properties`, create it or run a Flutter command once:

```properties
flutter.sdk=/absolute/path/to/flutter
sdk.dir=/absolute/path/to/android/sdk
```

## Android Testing Notes

Bluetooth Classic cannot be tested reliably on emulators. Install the debug APK on two physical Android devices, grant Bluetooth and location permissions, make one device discoverable, then connect from the other device.

## Protocol

BlueChat uses newline-delimited JSON over RFCOMM. Supported packet types are:

- `handshake`
- `message`
- `delivered`
- `read`

All runtime messaging works completely offline.

