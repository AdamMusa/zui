import QtQuick

// QtQuick/Sprite. One named animation state in a sprite sheet, together with
// the weighted transitions it takes when its duration elapses.
//
// A sprite_sequence or image_particle references its sprites by control id and
// reads `nativeSprite` from each.
//
// `frame_rate` and `frame_duration` keep Qt's -2 sentinel, which means "not
// set": a sprite that sets neither runs one frame per animation step. Qt also
// carries `frames` as a deprecated alias of `frameCount`, so only `frame_count`
// is exposed.
Item {
  id: spriteRoot
  property var renderer: null
  readonly property var nativeSprite: nativeSpriteState

  function transitions() {
    var value = renderer ? renderer.prop("to", {}) : {}
    if (!value || typeof value !== "object" || Array.isArray(value)) return ({})
    var weights = ({})
    for (var state in value) weights[String(state)] = Number(value[state])
    return weights
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  Sprite {
    id: nativeSpriteState
    name: String(spriteRoot.renderer ? spriteRoot.renderer.prop("name", "") : "")
    source: spriteRoot.renderer ? spriteRoot.renderer.assetUrl(spriteRoot.renderer.prop("source", "")) : ""
    frameCount: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_count", 1) : 1)
    frameWidth: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_width", 0) : 0)
    frameHeight: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_height", 0) : 0)
    frameX: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_x", 0) : 0)
    frameY: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_y", 0) : 0)
    frameRate: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_rate", -2) : -2)
    frameRateVariation: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_rate_variation", 0) : 0)
    frameDuration: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_duration", -2) : -2)
    frameDurationVariation: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("frame_duration_variation", 0) : 0)
    reverse: spriteRoot.renderer ? spriteRoot.renderer.prop("reverse", false) === true : false
    frameSync: spriteRoot.renderer ? spriteRoot.renderer.prop("frame_sync", false) === true : false
    duration: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("duration", -1) : -1)
    durationVariation: Number(spriteRoot.renderer ? spriteRoot.renderer.prop("duration_variation", 0) : 0)
    randomStart: spriteRoot.renderer ? spriteRoot.renderer.prop("random_start", false) === true : false
    to: spriteRoot.transitions()

    onEntered: spriteRoot.send("enter", { name: nativeSpriteState.name })
  }
}
