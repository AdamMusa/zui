import QtQuick
import QtGraphs

// An axis formatter decides where a 3D value axis puts its grid lines and
// labels. It is assigned to the axis above it; QML completes children before
// their parent, so an attach that finds no axis yet is retried once the current
// event loop pass has finished building the subtree.
Item {
  id: root
  required property var renderer

  property var nativeFormatter: null

  visible: false
  width: 0
  height: 0

  function axisHost() {
    var item = root.parent
    while (item) {
      if (item["zuiAxisHost"] === true) return item
      item = item.parent
    }
    return null
  }

  function attach() {
    if (root.nativeFormatter) return
    var host = root.axisHost()
    if (!host || !host.nativeAxis) return
    if (host.nativeAxis.formatter === undefined) {
      renderer.componentError("graph_formatter_axis_unsupported",
                              "Only a graph_value_3d_axis takes a formatter", {})
      return
    }
    root.nativeFormatter = formatterComponent.createObject(host.nativeAxis)
    if (root.nativeFormatter) host.nativeAxis.formatter = root.nativeFormatter
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeFormatter) return
    renderer.componentError("graph_formatter_without_axis",
                            "A graph_value_3d_axis_formatter must be declared inside a graph_value_3d_axis", {})
  }

  Component {
    id: formatterComponent
    Value3DAxisFormatter {
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeFormatter) Qt.callLater(root.attachOrReport)
  }
}
