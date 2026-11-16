import QtQuick
import Qt.labs.wavefrontmesh

Item {
  id: meshRoot
  property var renderer: null
  property alias shaderMesh: nativeMesh
  visible: false

  readonly property var errorNames: [
    "none", "invalid_source", "unsupported_face_shape", "unsupported_index_size", "file_not_found",
    "no_attributes", "missing_position_attribute", "missing_texture_coordinate_attribute",
    "missing_position_and_texture_coordinate_attributes", "too_many_attributes",
    "invalid_plane_definition"
  ]

  function hasPlane(name) {
    var values = renderer ? renderer.prop(name, null) : null
    return Array.isArray(values) && values.length === 3
  }

  function plane(name) {
    var values = renderer ? renderer.prop(name, []) : []
    if (!Array.isArray(values) || values.length !== 3) return Qt.vector3d(0, 0, 0)
    return Qt.vector3d(Number(values[0]), Number(values[1]), Number(values[2]))
  }

  function reportLastError() {
    if (!renderer || nativeMesh.lastError === WavefrontMesh.NoError) return
    var name = meshRoot.errorNames[nativeMesh.lastError] || String(nativeMesh.lastError)
    renderer.componentError("wavefront_mesh_" + name, "Wavefront mesh failed to load: " + name,
                            { source: String(nativeMesh.source), reason: name })
  }

  WavefrontMesh {
    id: nativeMesh
    source: renderer ? renderer.assetUrl(renderer.prop("source", "")) : ""
    onLastErrorChanged: meshRoot.reportLastError()
    onSourceChanged: meshRoot.reportLastError()
  }

  Binding {
    target: nativeMesh
    property: "projectionPlaneV"
    value: meshRoot.plane("projection_plane_v")
    when: meshRoot.hasPlane("projection_plane_v")
  }

  Binding {
    target: nativeMesh
    property: "projectionPlaneW"
    value: meshRoot.plane("projection_plane_w")
    when: meshRoot.hasPlane("projection_plane_w")
  }
}
