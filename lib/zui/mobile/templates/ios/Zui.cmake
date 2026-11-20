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

# Qt Quick 3D
# ZUI_USES_QUICK3D is ON whenever the bundled framework keeps a GPU 3D adapter
# (view_3d, model_view_3d and the rest of the QtQuick3D surface). Zui already
# links Qt6::Quick3D, the QML plugins of every QtQuick3D submodule, and the
# asset importer plugins RuntimeLoader needs. Extend it here when a provider
# SDK draws into the same scene:
#
# if(ZUI_USES_QUICK3D)
#   target_link_libraries(zui-host PRIVATE
#     "${ZUI_IOS_PROJECT_DIR}/Frameworks/ProviderRenderer.xcframework"
#   )
# endif()
