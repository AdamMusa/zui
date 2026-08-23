import QtQuick

Item {
  id: shaderRoot
  required property var renderer
  property real elapsedTime: Number(renderer.prop("time", 0))
  property int frameNumber: 0
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  function shaderUrl(value, fallback) {
    var name = String(value || "")
    if (name === "") name = String(renderer.prop("shader", fallback || ""))
    var builtins = ["passthrough", "grayscale", "wave", "pixelate", "vignette"]
    if (builtins.indexOf(name) >= 0) return Qt.resolvedUrl("Shaders/" + name + ".frag.qsb")
    return renderer.assetUrl(name)
  }

  function sourceRectangle() {
    var value = renderer.prop("source_rect", {})
    return Qt.rect(Number(value.x || 0), Number(value.y || 0), Number(value.width === undefined ? width : value.width), Number(value.height === undefined ? height : value.height))
  }

  Loader {
    id: sourceLoader
    anchors.fill: parent
    source: renderer.node && renderer.node.children && renderer.node.children.length > 0 ? Qt.resolvedUrl("../../ControlNode.qml") : ""
    onLoaded: renderer.configureFace(item, renderer.node.children[0])
  }

  ShaderEffectSource {
    id: sourceTexture
    sourceItem: sourceLoader
    sourceRect: shaderRoot.sourceRectangle()
    textureSize: Qt.size(Number(renderer.prop("texture_width", 0)), Number(renderer.prop("texture_height", 0)))
    format: {
      var value = String(renderer.prop("texture_format", "rgba8"))
      if (value === "rgba16f") return ShaderEffectSource.RGBA16F
      if (value === "rgba32f") return ShaderEffectSource.RGBA32F
      return ShaderEffectSource.RGBA8
    }
    samples: Number(renderer.prop("texture_samples", 0))
    wrapMode: {
      var value = String(renderer.prop("texture_wrap", "clamp"))
      if (value === "repeat") return ShaderEffectSource.Repeat
      if (value === "repeat_horizontal") return ShaderEffectSource.RepeatHorizontally
      if (value === "repeat_vertical") return ShaderEffectSource.RepeatVertically
      return ShaderEffectSource.ClampToEdge
    }
    textureMirroring: {
      var value = String(renderer.prop("texture_mirroring", "none"))
      if (value === "horizontal") return ShaderEffectSource.MirrorHorizontally
      if (value === "vertical") return ShaderEffectSource.MirrorVertically
      return ShaderEffectSource.NoMirroring
    }
    mipmap: renderer.prop("mipmap", false) === true
    live: renderer.prop("live", true) !== false
    recursive: renderer.prop("recursive", false) === true
    hideSource: true
  }

  ShaderEffect {
    id: nativeShader
    anchors.fill: parent
    property var source: sourceTexture
    property real time: shaderRoot.elapsedTime
    property vector2d resolution: Qt.vector2d(width, height)
    property vector2d mouse: Qt.vector2d(Number(renderer.prop("mouse_x", 0)), Number(renderer.prop("mouse_y", 0)))
    property real intensity: Number(renderer.prop("intensity", 1))
    property real amount: Number(renderer.prop("amount", 1))
    property real radius: Number(renderer.prop("radius", 1))
    property real progress: Number(renderer.prop("progress", 0))
    property real frequency: Number(renderer.prop("frequency", 1))
    property real amplitude: Number(renderer.prop("amplitude", 0.02))
    property color color: renderer.prop("color", "white")
    property color color2: renderer.prop("color2", "black")
    property vector4d parameters: {
      var values = renderer.prop("parameters", [])
      return Qt.vector4d(Number(values[0] || 0), Number(values[1] || 0), Number(values[2] || 0), Number(values[3] || 0))
    }
    fragmentShader: shaderRoot.shaderUrl(renderer.prop("fragment_shader", ""), "passthrough")
    vertexShader: renderer.assetUrl(renderer.prop("vertex_shader", ""))
    blending: renderer.prop("blending", true) !== false
    supportsAtlasTextures: renderer.prop("supports_atlas", false) === true
    mesh: Qt.size(Math.max(1, Number(renderer.prop("mesh_width", 1))), Math.max(1, Number(renderer.prop("mesh_height", 1))))
    cullMode: {
      var value = String(renderer.prop("cull_mode", "none"))
      if (value === "back") return ShaderEffect.BackFaceCulling
      if (value === "front") return ShaderEffect.FrontFaceCulling
      return ShaderEffect.NoCulling
    }
    onStatusChanged: {
      if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status, log: log })
      if (status === ShaderEffect.Error) renderer.componentError("shader_load_failed", log, { fragment_shader: String(fragmentShader), vertex_shader: String(vertexShader) })
    }
  }

  Timer {
    interval: Math.max(1, Math.round(1000 / Math.max(1, Number(renderer.prop("fps", 60)))))
    repeat: true
    running: renderer.prop("running", false) === true
    onTriggered: {
      shaderRoot.elapsedTime += interval / 1000
      shaderRoot.frameNumber += 1
      if (renderer.subscribed("frame")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "frame", { frame: shaderRoot.frameNumber, time: shaderRoot.elapsedTime })
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: mouse.x, y: mouse.y }) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { x: mouse.x, y: mouse.y }) }
  }
}
