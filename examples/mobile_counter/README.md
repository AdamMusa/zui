# Zui Mobile Counter

A touch-first sample for Zui's native iOS runtime. Precompiled Ruby bytecode, the in-process mruby
VM, and the Zui renderer are embedded in the application bundle; there is no child Ruby process and
no web view.

Build, install, and launch it in a compatible iOS Simulator:

```bash
zui mobile ios . \
  --qt-ios /path/to/Qt/6.8.3/ios \
  --qt-host /path/to/Qt/6.8.3/macos \
  --mruby /path/to/mruby \
  --mruby-json /path/to/mruby-json
```

The four dependency paths can instead be provided through `ZUI_QT_IOS`, `ZUI_QT_HOST`,
`ZUI_MRUBY_ROOT`, and `ZUI_MRUBY_JSON`.

The same Ruby application can still run on the desktop:

```bash
../../bin/zui run main.rb
```
