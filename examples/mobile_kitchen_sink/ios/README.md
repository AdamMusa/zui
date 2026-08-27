# iOS configuration

Zui passes these files to the Qt-generated Xcode project for every iOS build.

- Add privacy usage-description keys such as `NSCameraUsageDescription` to `Info.plist.in` before requesting protected access.
- Add capabilities such as associated domains or push notifications to `Zui.entitlements`, after enabling the same capability for the Apple app identifier.
- Add `LaunchScreen.storyboard` here to override the generated splash launch screen.
- Keep the bundle placeholders in `Info.plist.in`; CMake and Xcode replace them with values from `config.rb`.
- Put provider configuration files such as `GoogleService-Info.plist` directly in this directory; Zui copies otherwise-unrecognized root files into the application bundle.
- Put additional bundle files under `Resources/` and Objective-C, Objective-C++, C++, or Swift integration code under `Sources/`.
- Add SDK linking or framework embedding rules to `Zui.cmake`, and provider-specific Xcode build settings to `Zui.xcconfig`.

Do not add private signing keys or provisioning profiles to this directory.
