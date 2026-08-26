# Android configuration

Zui overlays this directory onto Qt's Android package template for every build.

- Add permissions and hardware features to `AndroidManifest.xml`.
- Keep the four `%%INSERT_...%%` markers and the Qt activity metadata; Qt replaces them while packaging.
- Add Android resources below `res/`, Java or Kotlin sources below `src/`, and optional Gradle customization in `build.gradle`.
- Never commit keystores or signing passwords. Zui uses the standard Android debug keystore for development builds.

Declaring a dangerous permission in the manifest does not grant it at runtime. The app must also request it when the feature is used.
