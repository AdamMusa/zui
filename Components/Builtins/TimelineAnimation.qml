import QtQuick
import QtQuick.Timeline

// QtQuick.Timeline/TimelineAnimation. Drives a timeline's current frame. The
// timeline it belongs to sets its target and property, so this component only
// carries the animation's own shape.
//
// A timeline references its animations by control id and reads
// `nativeTimelineAnimation` from each.
Item {
  id: timelineAnimationRoot
  property var renderer: null
  readonly property var nativeTimelineAnimation: nativeAnimation

  function loopsValue() {
    var value = renderer ? renderer.prop("loops", 1) : 1
    return String(value) === "infinite" || Number(value) < 0 ? Animation.Infinite : Math.max(1, Number(value))
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  TimelineAnimation {
    id: nativeAnimation
    from: Number(timelineAnimationRoot.renderer ? timelineAnimationRoot.renderer.prop("from", 0) : 0)
    to: Number(timelineAnimationRoot.renderer ? timelineAnimationRoot.renderer.prop("to", 0) : 0)
    duration: Number(timelineAnimationRoot.renderer ? timelineAnimationRoot.renderer.prop("duration", 250) : 250)
    easing.type: timelineAnimationRoot.renderer
      ? timelineAnimationRoot.renderer.easingType(timelineAnimationRoot.renderer.prop("easing", "linear"))
      : Easing.Linear
    loops: timelineAnimationRoot.loopsValue()
    pingPong: timelineAnimationRoot.renderer ? timelineAnimationRoot.renderer.prop("ping_pong", false) === true : false
    alwaysRunToEnd: timelineAnimationRoot.renderer ? timelineAnimationRoot.renderer.prop("always_run", false) === true : false
    running: timelineAnimationRoot.renderer ? timelineAnimationRoot.renderer.prop("running", false) === true : false
    paused: timelineAnimationRoot.renderer ? timelineAnimationRoot.renderer.prop("paused", false) === true : false

    onStarted: timelineAnimationRoot.send("start", {})
    onStopped: timelineAnimationRoot.send("stop", {})
    onFinished: timelineAnimationRoot.send("finish", {})
    onRunningChanged: timelineAnimationRoot.send("running_change", { value: nativeAnimation.running })
  }
}
