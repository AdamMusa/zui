# Android configuration

Zui overlays this directory onto Qt's Android package template for every build.

- Add permissions and hardware features to `AndroidManifest.xml`.
- Keep the four `%%INSERT_...%%` markers and the Qt activity metadata; Qt replaces them while packaging.
- Add Android resources below `res/`, Java or Kotlin sources below `src/`, and provider files such as `google-services.json` at this directory's root.
- Add external repositories, plugins, and SDK dependencies to `zui.gradle`. Zui applies it after the active Qt SDK's own `build.gradle`, so Qt upgrades do not leave a copied build script behind.
- A complete custom `build.gradle` is still supported for advanced integrations and takes precedence over Zui's generated wrapper.
- Put native C/C++ SDK linking and compile rules in `Zui.cmake`; it runs after Zui creates the Android target.
- Set service-required minimum, target, compile, or maximum Android API levels in `zui.gradle`. Manifest-level constraints such as a permission's `android:maxSdkVersion` stay in `AndroidManifest.xml`.
- Never commit keystores or signing passwords. Zui uses the standard Android debug keystore for development builds.

Declaring a dangerous permission in the manifest does not grant it at runtime. The app must also request it when the feature is used.
