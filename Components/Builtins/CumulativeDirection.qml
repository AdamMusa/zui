import QtQuick
import QtQuick.Particles

// QtQuick.Particles/CumulativeDirection. Sums the directions it is given, so a
// particle can carry several independent movement contributions at once.
//
// `directions` is a read-only Qt list property: it can be appended to but not
// reassigned, so a changed reference list rebuilds the native object instead of
// leaving stale contributions behind.
Item {
  id: cumulativeDirectionRoot
  property var renderer: null
  property var nativeDirection: null
  property string appliedDirections: ""

  function referencedIds() {
    var value = renderer ? renderer.prop("directions", []) : []
    var ids = Array.isArray(value) ? value : (String(value || "") === "" ? [] : [value])
    var names = []
    for (var index = 0; index < ids.length; index++) {
      var name = String(ids[index] || "")
      if (name !== "") names.push(name)
    }
    return names
  }

  function rebuild() {
    if (!renderer) return
    var ids = referencedIds()
    var resolved = []
    var resolvedIds = []
    for (var index = 0; index < ids.length; index++) {
      var host = renderer.findRenderedItem(ids[index])
      var direction = host ? host.nativeDirection : null
      if (direction) {
        resolved.push(direction)
        resolvedIds.push(ids[index])
      }
    }
    // A reference that has not rendered yet keeps the signature different, so
    // the next node revision picks it up instead of caching a partial sum.
    var signature = ids.join(",") + "|" + resolvedIds.join(",")
    if (signature === appliedDirections && nativeDirection) return
    var previous = nativeDirection
    nativeDirection = null
    if (previous) previous.destroy()
    var created = cumulativeDirectionFactory.createObject(cumulativeDirectionRoot)
    for (var slot = 0; slot < resolved.length; slot++) created.directions.push(resolved[slot])
    appliedDirections = signature
    nativeDirection = created
  }

  Component { id: cumulativeDirectionFactory; CumulativeDirection {} }

  Connections {
    target: cumulativeDirectionRoot.renderer
    function onNodeChanged() { cumulativeDirectionRoot.rebuild() }
  }
  Component.onCompleted: { rebuild(); Qt.callLater(rebuild) }
}
