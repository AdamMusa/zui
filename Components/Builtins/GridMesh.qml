import QtQuick

Item {
  id: meshRoot
  property var renderer: null
  property alias shaderMesh: nativeMesh
  visible: false

  GridMesh {
    id: nativeMesh
    resolution: Qt.size(Math.max(1, Math.round(Number(renderer ? renderer.prop("columns", 1) : 1))),
                        Math.max(1, Math.round(Number(renderer ? renderer.prop("rows", 1) : 1))))
  }
}
