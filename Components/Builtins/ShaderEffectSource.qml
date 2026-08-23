import QtQuick

Item {
  id: effectSourceRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  function rectangle() {
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
    id: nativeSource
    anchors.fill: parent
    sourceItem: sourceLoader
    sourceRect: effectSourceRoot.rectangle()
    textureSize: Qt.size(Number(renderer.prop("texture_width", 0)), Number(renderer.prop("texture_height", 0)))
    format: {
      var value = String(renderer.prop("format", "rgba8"))
      if (value === "rgba16f") return ShaderEffectSource.RGBA16F
      if (value === "rgba32f") return ShaderEffectSource.RGBA32F
      return ShaderEffectSource.RGBA8
    }
    samples: Number(renderer.prop("samples", 0))
    wrapMode: {
      var value = String(renderer.prop("wrap_mode", "clamp"))
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
    hideSource: renderer.prop("hide_source", true) !== false
    smooth: renderer.prop("smooth", true) !== false
  }

  Connections {
    target: renderer
    function onNodeChanged() {
      if (!nativeSource.live) nativeSource.scheduleUpdate()
      if (renderer.subscribed("update")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "update", {})
    }
  }
}
