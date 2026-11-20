# Qt QML modules on mobile targets

This is the audit of how a Qt QML module reaches an iOS or Android application built by
`zui mobile`, which modules reach one today, and which cannot reach one at all. It was written
against Qt **6.8.3** (`macos`, `ios` and `android_arm64_v8a` SDKs), which is the version
`Zui::Mobile::Setup::QT_VERSION` pins.

The machine-readable version of the same facts is `native/qt-modules.json`, which the build and the
test suite read; this document explains how the chain works and what was verified by hand.

## How a module reaches a device

A mobile build never lists its Qt modules. The chain is driven by the `import` lines of the QML
that survives tree shaking:

1. **`Zui::Mobile.prepare_framework`** copies the framework and runs `Zui::TreeShaker`, which keeps
   only the adapters the application references, then records the surviving imports in
   `zui-mobile.json` under `qml_modules`.
2. **`native/CMakeLists.txt`** compiles the surviving tree into the application's Qt resource
   (`qt_add_resources`, prefix `/zui`).
3. **Qt's import scanner** reads that resource. On iOS, `qt_import_qml_plugins(zui-host)` runs
   `qmlimportscanner` over the generated `.qrc` at configure time and links the static QML plugin of
   every module it finds. On Android, CMake writes the framework directories into the
   `qml-root-path` of `android-zui-host-deployment-settings.json`, and `androiddeployqt` scans them
   and copies the matching `qml/` module and its libraries into the APK.
4. **`zui_link_qt_modules()`** (`native/ZuiQtModules.cmake`) looks every import up in
   `native/qt-modules.json` and links the module's library explicitly, so the result no longer
   depends on the scanner alone, and fails the configure step when a module cannot work on the
   target or is missing from the SDK.
5. **Permissions**: `androiddeployqt` inserts the permissions a deployed Qt module declares at the
   `%%INSERT_PERMISSIONS` marker of the staged `AndroidManifest.xml`. Application-level permissions
   (camera, contacts, calendar, precise location) stay the application's own job, in
   `android/AndroidManifest.xml` and in `ios/Info.plist.in` usage descriptions.

### Why steps 3 and 4 both exist

Step 3 works because `find_package(Qt6 COMPONENTS Qml)` globs and includes *every*
`lib/cmake/Qt6Qml/QmlPlugins/Qt6*Config.cmake` in the SDK
(`__qt_internal_include_qml_plugin_packages` in `QtPublicPluginHelpers.cmake`), so the plugin target
of a module nobody asked for is already in scope when the scanner names it. When it is *not* in
scope, `qt6_import_qml_plugins` only warns — "there is no target by that name in the current scope.
The plugin will not be linked" — and the application starts and fails at the `import`.

That makes step 3 silent in exactly the case that matters, which is why step 4 was added.

### Evidence

Observed in the iOS catalog build at `tmp/mobile-catalog-ios-final` (a simulator build of the
mobile catalog example), whose framework retained 11 Qt modules:

* `xcode/.qt/qml_imports/zui-host_conf.cmake` lists 42 scanner entries, each with the plugin's link
  target, e.g. `NAME;QtSensors;PLUGIN;sensorsquickplugin;LINKTARGET;Qt6::SensorsQuickplugin`.
* `xcode/zui-host.xcodeproj/project.pbxproj` links `libdeclarative_locationplugin.a`,
  `libpositioningquickplugin.a`, `libtexttospeechqmlplugin.a`, `libqmlwebsocketsplugin.a`,
  `libqtwebviewquickplugin.a`, `QtSensorsQuick.framework`, `QtWebSockets.framework` and the
  `qtsensors_ios`, `qtposition_cl`, `qtgeoservices_osm`, `qtexttospeech_speechdarwin`,
  `darwinmediaplugin` backend plugins — **none of which `native/CMakeLists.txt` ever names**.

Observed in the Android kitchen-sink build at `tmp/mobile-kitchen-sink-android-final`, whose
framework retained 14 Qt modules:

* `build/android-zui-host-deployment-settings.json` has a `qml-root-path` array pointing at
  `framework/`, `framework/Components/Builtins`, `framework/Components/Builtins/Support`,
  `framework/Controls` and `framework/Theme` — the tree-shaken framework, not the source tree.
* The signed APK carries `lib/arm64-v8a/libQt6{Location,Positioning,PositioningQuick,Sensors,`
  `SensorsQuick,TextToSpeech,VirtualKeyboard,WebView,WebViewQuick,Multimedia,MultimediaQuick,`
  `QuickEffects,QuickShapes,QmlCore,QmlNetwork,LabsAnimation,LabsFolderListModel}_arm64-v8a.so`,
  which is the closure of the retained imports (plus `Qt6Svg` for the SVG image plugin and
  `Qt6Quick3DUtils`, which `Qt6QuickEffects` depends on) and nothing else.
* Its `AndroidManifest.xml` carries `INTERNET` and `WRITE_EXTERNAL_STORAGE` (Qt Core),
  `ACCESS_NETWORK_STATE` (Qt Network) and `MODIFY_AUDIO_SETTINGS` (Qt Multimedia) above the
  application's own permissions, inserted by `androiddeployqt` from
  `lib/Qt6*_arm64-v8a-android-dependencies.xml`.

So both mobile targets resolve Qt modules from the QML imports of the tree-shaken framework, and
the mechanism is generic: a module becomes reachable when an adapter imports it.

## Module status

76 public Qt QML modules exist in the Qt 6.8.3 SDKs (style implementations, `*.impl` and `*.private`
helpers, designer and test tooling and the virtual-keyboard internals are excluded as they are never
imported by an application). They divide into 28 reachable today, 41 available but unused, 4 that
cannot reach a mobile target and 4 that Qt always pulls in as a dependency — `QtQuick.Pdf` is
counted twice because it is reachable on iOS and impossible on Android.

### Reachable today — 28 modules

A shipped adapter imports each of these, so a build that keeps that adapter carries the module.

| Qt QML module | Imported by |
| --- | --- |
| `QtQuick` | every framework QML file (344) |
| `QtQuick.Controls` | 161 framework files |
| `QtQuick.Layouts` | 89 framework files |
| `QtQuick.Window` | 12 files, including `ApplicationWindow` |
| `QtQuick.Controls.Basic` | `DatePicker` |
| `QtQuick.Dialogs` | `ColorPicker`, `FilePicker`, `FolderPicker`, `FontPicker`, `MessageDialog` |
| `QtQuick.Effects` | `Blur`, `Colorize`, `DropShadow`, `Glow`, `MultiEffect`, `OpacityMask`, `RectangularShadow` |
| `QtQuick.Shapes` | `Circle`, `Gradient`, `Line`, `Path`, `Shape` |
| `QtQuick.Particles` | `ParticleSystem` |
| `QtQuick.VectorImage` | `VectorImage` |
| `QtQuick.Pdf` | `PdfView` — **iOS only**, see below |
| `QtQuick3D` | `Support/ModelView3dScene` |
| `QtQuick3D.AssetUtils` | `Support/ModelView3dScene` |
| `QtMultimedia` | 14 adapters, including `Camera`, `MediaPlayer`, `CaptureSession` |
| `QtSensors` | 16 sensor adapters |
| `QtPositioning` | 15 adapters, including `PositionSource` |
| `QtLocation` | 18 map adapters |
| `QtTextToSpeech` | `TextToSpeech` |
| `QtWebView` | `WebView` |
| `QtWebSockets` | `WebSocket`, `WebSocketServer` |
| `QtQuick.VirtualKeyboard` | `VirtualKeyboard`, `HandwritingInput`, `KeyboardContext`, `KeyboardTextField` |
| `QtQuick.VirtualKeyboard.Settings` | `KeyboardSettings` |
| `QtCore` | 9 adapters — the permission types and `SystemInfo`, `Settings`, `StandardPaths` |
| `QtNetwork` | `NetworkStatus` |
| `QtQml.Models` | `DelegateModel`, `SortFilterProxyModel`, `TableView`, `TreeView`, … |
| `Qt.labs.qmlmodels` | `Menu`, `MenuBar`, `ContextMenu` |
| `Qt.labs.folderlistmodel` | `FolderListModel` |
| `Qt.labs.lottieqt` | `LottieAnimation` |

`QtQml`, `QtQml.WorkerScript` and `QtQuick.Templates` are present in every build as well, together
with `QML` and the style implementations: Qt pulls them in as dependencies rather than zui importing
them, and `Zui::TreeShaker::BASE_QML_MODULES` keeps them for that reason.

### Available on both mobile targets, nothing imports them — 41 modules

These ship in both mobile SDKs and `zui mobile --fix` already installs their add-on, so the only
thing between them and a device is an adapter that imports them. No build wiring is missing.

* Charts and data: `QtCharts`, `QtGraphs`, `QtDataVisualization`
* 3D beyond the model viewer: `QtQuick3D.Helpers`, `QtQuick3D.Effects`, `QtQuick3D.Particles3D`,
  `QtQuick3D.ParticleEffects`, `QtQuick3D.Physics`, `QtQuick3D.Physics.Helpers`,
  `QtQuick3D.SpatialAudio`, `QtQuick.Scene2D`, `QtQuick.Scene3D`, and all six `Qt3D.*` modules
* Animation and effects: `QtQuick.Timeline`, `QtQuick.Timeline.BlendTrees`,
  `Qt5Compat.GraphicalEffects`, `Qt.labs.animation`
* Data and state: `QtQml.XmlListModel`, `QtQuick.LocalStorage`, `QtQml.StateMachine`, `QtScxml`,
  `Qt.labs.settings`, `Qt.labs.sharedimage`, `Qt.labs.wavefrontmesh`
* Transport: `QtWebChannel`, `QtRemoteObjects`, `QtGrpc`, `QtProtobuf`
* Styles and platform integration: `QtQuick.Controls.{Fusion,Imagine,Material,Universal,FluentWinUI3}`,
  `QtQuick.NativeStyle`, `Qt.labs.platform`, `QtQuick.Dialogs.quickimpl`

Two notes on this group:

* `QtQuick.LocalStorage` needs the `sqldrivers` plugins. `Zui::TreeShaker#prune_native_plugins`
  keeps the sqlite driver for a desktop native client when the module is retained; on mobile that
  path does not run at all, because `Zui::Mobile.prepare_framework` shakes the framework with
  `native: nil` and Qt's own static plugin import (iOS) or `androiddeployqt` plugin list (Android)
  decides which plugins ship.
* `Qt.labs.platform` opens native dialogs and menus. On iOS and Android most of its types have no
  implementation, so it is a poor substitute for `QtQuick.Dialogs` even though it loads.

### Cannot reach a mobile target — 4 modules

| Qt QML module | Target | Reason |
| --- | --- | --- |
| `QtQuick.Pdf` | Android | Qt 6.8.3 ships no Android build of Qt PDF. The `qtpdf` add-on exists for host and iOS only, which is why `Zui::Mobile::Setup::QT_ANDROID_MODULES` deliberately omits it while `QT_IOS_MODULES` includes it. `pdf_view` is an iOS-only capability. |
| `QtQuick3D.Xr` | iOS | Qt Quick 3D Xr targets visionOS and Android XR; the iOS SDK ships no such module. |
| `QtQuick.Controls.macOS` | iOS, Android | Desktop native style; host SDK only. |
| `QtQuick.Controls.iOS` | Android | The iOS native style ships in the host and iOS SDKs only. It is selected through the Controls style name rather than imported. |

Each of these reasons is recorded in `native/qt-modules.json`, and `zui_link_qt_modules()` repeats
it as a configure error when a build keeps an adapter that imports the module. Before that, an
Android build that kept `PdfView` configured, compiled, installed and then failed at the `import`
on the device with nothing in the build output.

## Findings

1. **The wiring is generic, but it was not verifiable.** Until `native/qt-modules.json` existed,
   nothing in the repo recorded which modules reach a target, so the only way to answer the question
   was to build an app, unzip the APK and read the Xcode link line — which is what this audit did.
2. **The one real "cannot work" case was silent.** `QtQuick.Pdf` on Android now fails at configure
   time with the reason instead of on the device.
3. **Two framework runtime assets never reached a mobile build**: the `Support/*.js` library
   `ModelView3d` imports and the precompiled `Shaders/*.frag.qsb` files `ShaderEffect` resolves were
   not in the Qt resource globs, so `model_view_3d` and `shader_effect` could not work on a device.
   Fixed separately, with a test that reads the globs out of `native/CMakeLists.txt`.
4. **Every Controls style is linked on iOS.** The static build links the Basic, Fusion, Imagine,
   Material, Universal, FluentWinUI3 and iOS style frameworks and their plugins, because the
   scanner resolves `QtQuick.Controls` to all of them. Only the configured style is used at runtime,
   so this is binary size rather than a defect, but it is the largest remaining trim available to a
   mobile build.
5. **`QtQuick3D` reaches both targets through one adapter.** `ModelView3dScene` imports it behind a
   `Loader`, and `Support/OptionalModuleState.js` remembers a failed probe, so an application that
   never uses `model_view_3d` pays nothing and one that does gets a reported component error rather
   than a blank item when the module is absent. That pattern is the model for any further optional
   module.

## Adding a Qt module

1. Write the adapter and `import` the module as usual.
2. If no adapter imported that module before, add its entry to `native/qt-modules.json`
   (`rake qt:modules` regenerates the file from the installed SDKs).
3. Run `rake test`. `test/qt_modules_test.rb` fails when the framework imports a module the registry
   does not describe, and when a module that is missing from a mobile target has no recorded reason.
