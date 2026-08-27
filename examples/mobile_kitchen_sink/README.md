# Zui Mobile Kitchen Sink

A native acceptance app for Zui's mobile runtime and tree-shaken Qt/QML catalog.

It keeps every capability honest: permission prompts, hardware availability, service status,
and runtime errors are surfaced in the Diagnostics card. The app covers camera preview and photo
capture, audio recording and playback, accelerometer-based shake detection, touch handlers, GPS,
maps, charts, speech, WebView, virtual keyboard, storage, settings, clipboard, and device/network
information in one responsive safe-area interface.

The checked-in `Gemfile.lock` fixes the app's Ruby dependency graph. Hardware-backed tests such
as camera, microphone, Bluetooth, GPS, and shake should be completed on a physical device; the
iOS Simulator is the fast render, scrolling, touch, chart, WebView, and service smoke test.

Enable the editable platform overlays once, then build either target:

```sh
zui mobile --enable examples/mobile_kitchen_sink
zui build ios
zui build android
```
