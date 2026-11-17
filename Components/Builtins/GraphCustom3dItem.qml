import QtQuick
import QtGraphs

// A custom 3D item is placed in a graph's own coordinate space. The graph takes
// ownership through addCustomItem(), so the adapter releases it again on
// destruction rather than deleting it underneath the graph.
Item {
  id: root
  required property var renderer

  property var nativeItem: null
  property var ownerGraph: null

  visible: false
  width: 0
  height: 0

  function graphsHost() {
    var item = root.parent
    while (item) {
      if (item["zuiGraphsHost"] === true) return item
      item = item.parent
    }
    return null
  }

  // A node property carries a vector as [x, y, z] or {x:, y:, z:}.
  function vector3dFor(key, fallback) {
    var value = renderer.prop(key, null)
    if (Array.isArray(value)) return Qt.vector3d(Number(value[0]), Number(value[1]), Number(value[2]))
    if (value !== null && typeof value === "object") {
      return Qt.vector3d(Number(value.x), Number(value.y), Number(value.z))
    }
    return fallback
  }

  // Rotation arrives as an axis plus an angle in degrees, which is far easier to
  // write than a raw quaternion. QML's Qt object only offers the
  // Qt.quaternion(w, x, y, z) factory, so the conversion is done here.
  function rotationFor() {
    var axis = root.vector3dFor("rotation_axis", Qt.vector3d(0, 1, 0))
    var degrees = Number(renderer.prop("rotation_angle", 0))
    var length = Math.sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z)
    if (length === 0 || degrees === 0) return Qt.quaternion(1, 0, 0, 0)

    var half = degrees * Math.PI / 360
    var scale = Math.sin(half) / length
    return Qt.quaternion(Math.cos(half), axis.x * scale, axis.y * scale, axis.z * scale)
  }

  function attach() {
    if (root.nativeItem) return
    var host = root.graphsHost()
    if (!host) {
      renderer.componentError("graph_custom_item_without_graph",
                              "A graph_custom_3d_item must be declared inside a 3D graph", {})
      return
    }
    root.ownerGraph = host
    root.nativeItem = itemComponent.createObject(host)
    if (root.nativeItem) host.addCustomItem(root.nativeItem)
  }

  Component {
    id: itemComponent
    Custom3DItem {
      position: root.vector3dFor("position", Qt.vector3d(0, 0, 0))
      positionAbsolute: root.renderer.prop("position_absolute", false) === true
      scaling: root.vector3dFor("scaling", Qt.vector3d(0.1, 0.1, 0.1))
      scalingAbsolute: root.renderer.prop("scaling_absolute", true) !== false
      rotation: root.rotationFor()
      visible: root.renderer.prop("item_visible", true) !== false
      shadowCasting: root.renderer.prop("shadow_casting", true) !== false
      meshFile: String(root.renderer.prop("mesh_file", ""))
      textureFile: String(root.renderer.prop("texture_file", ""))
    }
  }

  Component.onCompleted: root.attach()
  // addCustomItem transfers ownership to the graph, so release it rather than
  // destroying an object the graph still holds.
  Component.onDestruction: {
    if (root.ownerGraph && root.nativeItem) root.ownerGraph.releaseCustomItem(root.nativeItem)
    root.nativeItem = null
    root.ownerGraph = null
  }
}
