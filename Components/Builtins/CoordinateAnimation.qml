import QtQuick
import QtPositioning

Item {
  id: root
  required property var renderer
  readonly property var targetItem: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  property bool requestedRunning: false
  visible: false

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  function loopsValue() {
    var value = renderer.prop("loops", 1)
    return String(value) === "infinite" || Number(value) < 0 ? Animation.Infinite : Math.max(1, Number(value))
  }
  function directionValue() {
    var value = String(renderer.prop("direction", "shortest"))
    if (value === "west") return CoordinateAnimation.West
    if (value === "east") return CoordinateAnimation.East
    return CoordinateAnimation.Shortest
  }
  function coordinate(latitude, longitude, altitude) {
    return QtPositioning.coordinate(Number(latitude), Number(longitude), Number(altitude))
  }
  function synchronize(restart) {
    if (!renderer) return
    requestedRunning = renderer.prop("running", false) === true
    if (renderer.prop("paused", false) === true) { nativeAnimation.pause(); return }
    if (!requestedRunning) { delayTimer.stop(); nativeAnimation.stop(); return }
    if (restart || !nativeAnimation.running) {
      nativeAnimation.stop()
      var delay = Math.max(0, Number(renderer.prop("delay", 0)))
      if (delay > 0) { delayTimer.interval = delay; delayTimer.restart() } else nativeAnimation.start()
    } else if (nativeAnimation.paused) nativeAnimation.resume()
  }

  Timer { id: delayTimer; repeat: false; onTriggered: if (root.requestedRunning) nativeAnimation.start() }
  CoordinateAnimation {
    id: nativeAnimation
    target: root.targetItem
    property: String(root.renderer.prop("property", "center"))
    from: root.coordinate(root.renderer.prop("from_latitude", 0), root.renderer.prop("from_longitude", 0), root.renderer.prop("from_altitude", 0))
    to: root.coordinate(root.renderer.prop("to_latitude", 0), root.renderer.prop("to_longitude", 0), root.renderer.prop("to_altitude", 0))
    direction: root.directionValue()
    duration: Number(root.renderer.prop("duration", 250))
    easing.type: root.renderer.easingType(root.renderer.prop("easing", "in_out_quad"))
    loops: root.loopsValue()
    onStarted: root.send("start", {})
    onStopped: root.send("stop", {})
    onFinished: root.send("finish", {})
    onRunningChanged: root.send("running_change", { value: nativeAnimation.running })
  }
  Connections { target: renderer; function onNodeChanged() { root.synchronize(true) } }
  Component.onCompleted: {
    if (!targetItem) renderer.componentError("coordinate_animation_target_missing", "The coordinate animation target was not found", { target: String(renderer.prop("target", "")) })
    synchronize(false)
  }
}
