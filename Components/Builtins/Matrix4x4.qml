import QtQuick

Item {
  id: matrixRoot
  required property var renderer
  property string reportedMatrixKey: ""
  implicitWidth: Number(renderer.prop("width", matrixContent.implicitWidth))
  implicitHeight: Number(renderer.prop("height", matrixContent.implicitHeight))
  clip: renderer.prop("clip", false) === true

  function requestedValues() {
    var values = renderer.prop("matrix", null)
    return Array.isArray(values) ? values : null
  }

  function resolvedMatrix() {
    var values = requestedValues()
    if (!values || values.length !== 16) return Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
    return Qt.matrix4x4(
      Number(values[0]), Number(values[1]), Number(values[2]), Number(values[3]),
      Number(values[4]), Number(values[5]), Number(values[6]), Number(values[7]),
      Number(values[8]), Number(values[9]), Number(values[10]), Number(values[11]),
      Number(values[12]), Number(values[13]), Number(values[14]), Number(values[15]))
  }

  function reportInvalidMatrix() {
    var values = requestedValues()
    if (!values || values.length === 16) return
    var key = values.join(",")
    if (key === reportedMatrixKey) return
    reportedMatrixKey = key
    renderer.componentError("matrix_rejected",
      "matrix4x4 requires exactly 16 row-major values", { length: values.length })
  }

  transform: Matrix4x4 { matrix: matrixRoot.resolvedMatrix() }

  Item {
    id: matrixContent
    anchors.fill: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  Component.onCompleted: reportInvalidMatrix()
  Connections { target: renderer; function onNodeChanged() { matrixRoot.reportInvalidMatrix() } }
}
