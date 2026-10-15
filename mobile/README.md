# Pluris Haven mobile app

The Pluris Haven client is built with Flutter for Android and iOS.

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

Android Studio's default `app` run configuration launches a debug build. Debug
builds use the separate `works.endoftime.plurishaven.debug` package and appear
as **Pluris Haven (Debug)**, so they can be installed beside a release build.
Use `mise exec -- flutter run --release` when release-mode behaviour is needed;
this does not reproduce the signed publication workflow.
