import QtQuick

Item {
  id: meshRoot
  property var renderer: null
  property alias shaderMesh: nativeMesh
  visible: false

  function tileMode(name, fallback) {
    var mode = String(renderer ? renderer.prop(name, fallback) : fallback)
    if (mode === "repeat") return BorderImageMesh.Repeat
    if (mode === "round") return BorderImageMesh.Round
    return BorderImageMesh.Stretch
  }

  BorderImageMesh {
    id: nativeMesh
    size: Qt.size(Math.max(0, Math.round(Number(renderer ? renderer.prop("source_width", 0) : 0))),
                  Math.max(0, Math.round(Number(renderer ? renderer.prop("source_height", 0) : 0))))
    horizontalTileMode: meshRoot.tileMode("horizontal_tile_mode", "stretch")
    verticalTileMode: meshRoot.tileMode("vertical_tile_mode", "stretch")
    border.left: Math.max(0, Math.round(Number(renderer ? renderer.prop("border_left", 0) : 0)))
    border.right: Math.max(0, Math.round(Number(renderer ? renderer.prop("border_right", 0) : 0)))
    border.top: Math.max(0, Math.round(Number(renderer ? renderer.prop("border_top", 0) : 0)))
    border.bottom: Math.max(0, Math.round(Number(renderer ? renderer.prop("border_bottom", 0) : 0)))
  }
}
