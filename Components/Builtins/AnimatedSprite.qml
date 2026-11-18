import QtQuick

// QtQuick/AnimatedSprite. Plays a single sprite sheet, which is what a frame
// animation exported as a strip needs and what animated_image cannot do because
// it only reads whole GIF or APNG files.
//
// `frame_rate` and `frame_duration` keep Qt's -2 sentinel, which means "not
// set": setting neither advances one frame per animation step.
// `finish_behavior` is "initial_frame" or "final_frame".
Item {
  id: animatedSpriteRoot
  property var renderer: null
  property bool lastPublishedRunning: false

  implicitWidth: nativeSprite.implicitWidth
  implicitHeight: nativeSprite.implicitHeight

  function loopsValue() {
    var value = renderer ? renderer.prop("loops", -1) : -1
    return String(value) === "infinite" || Number(value) < 0 ? Animation.Infinite : Math.max(1, Number(value))
  }

  function finishBehaviorValue() {
    var behavior = String(renderer ? renderer.prop("finish_behavior", "initial_frame") : "initial_frame")
    return behavior === "final_frame" ? AnimatedSprite.FinishAtFinalFrame : AnimatedSprite.FinishAtInitialFrame
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function publishRunning() {
    if (!renderer || nativeSprite.running === lastPublishedRunning) return
    lastPublishedRunning = nativeSprite.running
    send("running_change", { value: nativeSprite.running })
    send(nativeSprite.running ? "start" : "stop", {})
  }

  AnimatedSprite {
    id: nativeSprite
    anchors.fill: parent
    source: animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.assetUrl(animatedSpriteRoot.renderer.prop("source", "")) : ""
    running: animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("running", true) !== false : true
    paused: animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("paused", false) === true : false
    interpolate: animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("interpolate", true) !== false : true
    reverse: animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("reverse", false) === true : false
    frameSync: animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("frame_sync", false) === true : false
    frameCount: Number(animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("frame_count", 1) : 1)
    frameWidth: Number(animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("frame_width", 0) : 0)
    frameHeight: Number(animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("frame_height", 0) : 0)
    frameX: Number(animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("frame_x", 0) : 0)
    frameY: Number(animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("frame_y", 0) : 0)
    frameRate: Number(animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("frame_rate", -2) : -2)
    frameDuration: Number(animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("frame_duration", -2) : -2)
    loops: animatedSpriteRoot.loopsValue()
    currentFrame: Number(animatedSpriteRoot.renderer ? animatedSpriteRoot.renderer.prop("current_frame", 0) : 0)
    finishBehavior: animatedSpriteRoot.finishBehaviorValue()

    onFinished: animatedSpriteRoot.send("finish", {})
    onCurrentFrameChanged: animatedSpriteRoot.send("frame_change", { value: nativeSprite.currentFrame })
    onRunningChanged: animatedSpriteRoot.publishRunning()
  }

  Component.onCompleted: publishRunning()
}
