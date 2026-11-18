import QtQuick

// QtQuick/SpriteSequence. Plays several named sprite states and moves between
// them, either by weighted chance from each sprite's own transitions or by
// being sent toward a goal.
//
// `sprites` references sprite components by control id. Qt's sprites list is a
// read-only list property, so sprites are appended once each and a reference
// cannot later be withdrawn. `jump_to` with a changed `jump_revision` jumps
// straight to a state instead of easing toward it.
Item {
  id: spriteSequenceRoot
  property var renderer: null
  property var appliedSprites: []
  property int handledJumpRevision: -1

  implicitWidth: nativeSequence.implicitWidth
  implicitHeight: nativeSequence.implicitHeight

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

  function applySprites() {
    if (!renderer) return
    var ids = stringList(renderer.prop("sprites", []))
    for (var index = 0; index < ids.length; index++) {
      if (appliedSprites.indexOf(ids[index]) >= 0) continue
      var host = renderer.findRenderedItem(ids[index])
      var sprite = host ? host.nativeSprite : null
      if (!sprite) continue
      nativeSequence.sprites.push(sprite)
      appliedSprites = appliedSprites.concat([ids[index]])
    }
  }

  function handleJump() {
    if (!renderer) return
    var revision = Number(renderer.prop("jump_revision", 0))
    var state = String(renderer.prop("jump_to", ""))
    if (revision === handledJumpRevision || state === "") return
    handledJumpRevision = revision
    nativeSequence.jumpTo(state)
    send("jump", { name: state, revision: revision })
  }

  SpriteSequence {
    id: nativeSequence
    anchors.fill: parent
    running: spriteSequenceRoot.renderer ? spriteSequenceRoot.renderer.prop("running", true) !== false : true
    interpolate: spriteSequenceRoot.renderer ? spriteSequenceRoot.renderer.prop("interpolate", true) !== false : true
    goalSprite: String(spriteSequenceRoot.renderer ? spriteSequenceRoot.renderer.prop("goal_sprite", "") : "")

    onCurrentSpriteChanged: spriteSequenceRoot.send("current_change", { name: nativeSequence.currentSprite })
    onRunningChanged: spriteSequenceRoot.send("running_change", { value: nativeSequence.running })
  }

  Connections {
    target: spriteSequenceRoot.renderer
    function onNodeChanged() { spriteSequenceRoot.applySprites(); spriteSequenceRoot.handleJump() }
  }
  Component.onCompleted: { applySprites(); Qt.callLater(applySprites); handleJump() }
}
