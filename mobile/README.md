# Pluris Haven Mobile

Flutter app.

## Run

```sh
mise exec -- flutter analyze
mise exec -- flutter test
mise exec -- flutter run
```

From the repo root, use the pinned SDK:

Install the Android SDK and set `ANDROID_SDK_ROOT` (or `ANDROID_HOME`) before
running the bootstrap script. It creates ignored `android/local.properties`
only if that file is absent.

```sh
mise trust
mise install
cd mobile
./tool/bootstrap_android_studio.sh
mise exec -- flutter run
```

Open this directory in Android Studio.
