import QtQuick

Item {
  id: graphicsRoot
  required property var renderer
  property int handledRefreshRevision: -1
  implicitWidth: 0
  implicitHeight: 0

  function apiName(value) {
    if (value === GraphicsInfo.Software) return "software"
    if (value === GraphicsInfo.OpenVG) return "openvg"
    if (value === GraphicsInfo.OpenGL) return "opengl"
    if (value === GraphicsInfo.Direct3D11) return "direct3d11"
    if (value === GraphicsInfo.Direct3D12) return "direct3d12"
    if (value === GraphicsInfo.Vulkan) return "vulkan"
    if (value === GraphicsInfo.Metal) return "metal"
    if (value === GraphicsInfo.Null) return "null"
    return "unknown"
  }

  function shaderTypeName(value) {
    if (value === GraphicsInfo.GLSL) return "glsl"
    if (value === GraphicsInfo.HLSL) return "hlsl"
    if (value === GraphicsInfo.RhiShader) return "rhi"
    return "unknown"
  }

  function shaderSourceName(value) {
    var names = []
    if (value & GraphicsInfo.ShaderSourceString) names.push("string")
    if (value & GraphicsInfo.ShaderSourceFile) names.push("file")
    if (value & GraphicsInfo.ShaderByteCode) names.push("byte_code")
    return names
  }

  function profileName(value) {
    if (value === GraphicsInfo.OpenGLCoreProfile) return "core"
    if (value === GraphicsInfo.OpenGLCompatibilityProfile) return "compatibility"
    return "none"
  }

  function renderableTypeName(value) {
    if (value === GraphicsInfo.SurfaceFormatOpenGL) return "opengl"
    if (value === GraphicsInfo.SurfaceFormatOpenGLES) return "opengles"
    return "unspecified"
  }

  function publish() {
    var info = graphicsRoot.GraphicsInfo
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "graphics", {
      api: graphicsRoot.apiName(info.api),
      shader_type: graphicsRoot.shaderTypeName(info.shaderType),
      shader_compilation: info.shaderCompilationType === GraphicsInfo.OfflineCompilation
        ? "offline" : "runtime",
      shader_sources: graphicsRoot.shaderSourceName(info.shaderSourceType),
      major_version: info.majorVersion, minor_version: info.minorVersion,
      profile: graphicsRoot.profileName(info.profile),
      renderable_type: graphicsRoot.renderableTypeName(info.renderableType)
    })
  }

  function refresh() {
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
  }

  Component.onCompleted: refresh()
  Connections { target: renderer; function onNodeChanged() { graphicsRoot.refresh() } }
  Connections {
    target: graphicsRoot.GraphicsInfo
    enabled: renderer.prop("watch", true) !== false
    function onApiChanged() { graphicsRoot.publish() }
    function onShaderTypeChanged() { graphicsRoot.publish() }
  }
}
