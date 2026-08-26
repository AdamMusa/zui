# This file is included after Zui creates the iOS target named zui-host.
# Use it for external SDKs that require native libraries or prebuilt frameworks.
#
# Example link rule:
# target_link_libraries(zui-host PRIVATE
#   "${ZUI_IOS_PROJECT_DIR}/Frameworks/Provider.xcframework"
# )
#
# Dynamic frameworks can also be embedded with Xcode target properties:
# set_property(TARGET zui-host APPEND PROPERTY XCODE_EMBED_FRAMEWORKS
#   "${ZUI_IOS_PROJECT_DIR}/Frameworks/Provider.framework"
# )
