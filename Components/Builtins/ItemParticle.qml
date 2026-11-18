import QtQuick
import QtQuick.Particles

// QtQuick.Particles/ItemParticle. Paints a group with live Zui items instead of
// a texture, so interactive controls can ride a particle system.
//
// Qt's `delegate` takes a QQmlComponent, which has no Ruby representation, so
// the exposed path is Qt's other documented mechanism: `items` lists rendered
// nodes by control id and the particle take()s them. The listed nodes keep
// their own place in the tree, so Zui still owns their lifetime. Removing an id
// gives the item back, and `frozen` freezes every item it currently holds.
Item {
  id: itemParticleRoot
  property var renderer: null
  property var takenItems: []
  property bool appliedFrozen: false

  readonly property var particleSystem: nativeHandle(renderer ? renderer.prop("system", "") : "", "nativeParticleSystem")

  function nativeHandle(controlId, handle) {
    var name = String(controlId || "")
    if (!renderer || name === "") return null
    var host = renderer.findRenderedItem(name)
    if (!host) return null
    var value = host[handle]
    return value === undefined ? null : value
  }

  function stringList(value) {
    if (Array.isArray(value)) {
      var names = []
      for (var index = 0; index < value.length; index++) names.push(String(value[index]))
      return names
    }
    var single = String(value === undefined || value === null ? "" : value)
    return single === "" ? [] : [single]
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function synchronizeItems() {
    if (!renderer) return
    var ids = stringList(renderer.prop("items", []))
    var kept = []
    for (var held = 0; held < takenItems.length; held++) {
      var entry = takenItems[held]
      if (ids.indexOf(entry.controlId) >= 0) {
        kept.push(entry)
        continue
      }
      nativeItemParticle.give(entry.item)
      send("give", { item: entry.controlId })
    }
    for (var index = 0; index < ids.length; index++) {
      var controlId = ids[index]
      var alreadyHeld = false
      for (var slot = 0; slot < kept.length; slot++) if (kept[slot].controlId === controlId) alreadyHeld = true
      if (alreadyHeld) continue
      var item = renderer.findRenderedItem(controlId)
      if (!item) continue
      nativeItemParticle.take(item, true)
      kept.push({ controlId: controlId, item: item })
      send("take", { item: controlId })
    }
    takenItems = kept
    applyFrozen(true)
  }

  function applyFrozen(force) {
    if (!renderer) return
    var frozen = renderer.prop("frozen", false) === true
    if (!force && frozen === appliedFrozen) return
    appliedFrozen = frozen
    for (var index = 0; index < takenItems.length; index++) {
      if (frozen) nativeItemParticle.freeze(takenItems[index].item)
      else nativeItemParticle.unfreeze(takenItems[index].item)
    }
  }

  ItemParticle {
    id: nativeItemParticle
    system: itemParticleRoot.particleSystem
    groups: itemParticleRoot.stringList(itemParticleRoot.renderer ? itemParticleRoot.renderer.prop("groups", []) : [])
    fade: itemParticleRoot.renderer ? itemParticleRoot.renderer.prop("fade", true) !== false : true
    x: Number(itemParticleRoot.renderer ? itemParticleRoot.renderer.prop("x", 0) : 0)
    y: Number(itemParticleRoot.renderer ? itemParticleRoot.renderer.prop("y", 0) : 0)
    width: Number(itemParticleRoot.renderer ? itemParticleRoot.renderer.prop("width", 0) : 0)
    height: Number(itemParticleRoot.renderer ? itemParticleRoot.renderer.prop("height", 0) : 0)

    onCountChanged: itemParticleRoot.send("count_change", {})
  }

  Connections {
    target: itemParticleRoot.renderer
    function onNodeChanged() { itemParticleRoot.synchronizeItems() }
  }
  Component.onCompleted: { synchronizeItems(); Qt.callLater(synchronizeItems) }
}
