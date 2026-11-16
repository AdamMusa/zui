import QtQuick
import QtQuick.Particles

// QtQuick.Particles/ImageParticle. Paints the particles of one or more groups
// in a system referenced by control id, so a system can mix several looks.
//
// `x_vector` and `y_vector` reference a direction component by control id and
// deform the particle quad. Unset they stay null, which is Qt's own default
// upright quad.
//
// `sprites` references sprite components by control id. Qt's sprites list is a
// read-only list property, so sprites are appended once each and a reference
// cannot later be withdrawn.
Item {
  id: imageParticleRoot
  property var renderer: null
  property var appliedSprites: []
  property int lastPublishedStatus: -1

  readonly property var particleSystem: nativeHandle(renderer ? renderer.prop("system", "") : "", "nativeParticleSystem")
  readonly property var horizontalVector: nativeHandle(renderer ? renderer.prop("x_vector", "") : "", "nativeDirection")
  readonly property var verticalVector: nativeHandle(renderer ? renderer.prop("y_vector", "") : "", "nativeDirection")

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

  function entryEffectValue() {
    var effect = String(renderer ? renderer.prop("entry_effect", "fade") : "fade")
    if (effect === "none") return ImageParticle.None
    if (effect === "scale") return ImageParticle.Scale
    return ImageParticle.Fade
  }

  function statusName(status) {
    if (status === ImageParticle.Ready) return "ready"
    if (status === ImageParticle.Loading) return "loading"
    if (status === ImageParticle.Error) return "error"
    return "null"
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function publishStatus() {
    if (!renderer || nativeImageParticle.status === lastPublishedStatus) return
    lastPublishedStatus = nativeImageParticle.status
    send("status", { value: statusName(nativeImageParticle.status) })
    if (nativeImageParticle.status === ImageParticle.Error) {
      renderer.componentError("particle_texture_unavailable", "The particle texture could not be loaded",
        { source: String(renderer.prop("source", "")) })
    }
  }

  function applySprites() {
    if (!renderer) return
    var ids = stringList(renderer.prop("sprites", []))
    for (var index = 0; index < ids.length; index++) {
      if (appliedSprites.indexOf(ids[index]) >= 0) continue
      var sprite = nativeHandle(ids[index], "nativeSprite")
      if (!sprite) continue
      nativeImageParticle.sprites.push(sprite)
      appliedSprites = appliedSprites.concat([ids[index]])
    }
  }

  ImageParticle {
    id: nativeImageParticle
    system: imageParticleRoot.particleSystem
    groups: imageParticleRoot.stringList(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("groups", []) : [])
    source: imageParticleRoot.renderer ? imageParticleRoot.renderer.assetUrl(imageParticleRoot.renderer.prop("source", "")) : ""
    colorTable: imageParticleRoot.renderer ? imageParticleRoot.renderer.assetUrl(imageParticleRoot.renderer.prop("color_table", "")) : ""
    sizeTable: imageParticleRoot.renderer ? imageParticleRoot.renderer.assetUrl(imageParticleRoot.renderer.prop("size_table", "")) : ""
    opacityTable: imageParticleRoot.renderer ? imageParticleRoot.renderer.assetUrl(imageParticleRoot.renderer.prop("opacity_table", "")) : ""
    // Qt leaves the texture unmodified until color is assigned, and its unset
    // property reads back black. White is the identity multiplier, so this
    // default matches Qt's visual default rather than its property default.
    color: imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("color", "white") : "white"
    colorVariation: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("color_variation", 0) : 0)
    redVariation: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("red_variation", 0) : 0)
    greenVariation: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("green_variation", 0) : 0)
    blueVariation: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("blue_variation", 0) : 0)
    alpha: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("alpha", 1) : 1)
    alphaVariation: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("alpha_variation", 0) : 0)
    rotation: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("rotation", 0) : 0)
    rotationVariation: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("rotation_variation", 0) : 0)
    rotationVelocity: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("rotation_velocity", 0) : 0)
    rotationVelocityVariation: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("rotation_velocity_variation", 0) : 0)
    autoRotation: imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("auto_rotation", false) === true : false
    xVector: imageParticleRoot.horizontalVector
    yVector: imageParticleRoot.verticalVector
    spritesInterpolate: imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("sprites_interpolate", true) !== false : true
    entryEffect: imageParticleRoot.entryEffectValue()
    x: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("x", 0) : 0)
    y: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("y", 0) : 0)
    width: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("width", imageParticleRoot.parent ? imageParticleRoot.parent.width : 0) : 0)
    height: Number(imageParticleRoot.renderer ? imageParticleRoot.renderer.prop("height", imageParticleRoot.parent ? imageParticleRoot.parent.height : 0) : 0)

    onStatusChanged: imageParticleRoot.publishStatus()
    onCountChanged: imageParticleRoot.send("count_change", {})
  }

  Connections {
    target: imageParticleRoot.renderer
    function onNodeChanged() { imageParticleRoot.applySprites() }
  }
  Component.onCompleted: { applySprites(); Qt.callLater(applySprites); publishStatus() }
}
