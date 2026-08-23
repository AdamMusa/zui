import QtQuick

Item {
  id: driver
  required property var renderer
  required property string animationType
  readonly property var targetItem: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  property bool requestedRunning: false

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  function loopsValue() {
    var value = renderer.prop("loops", 1)
    return String(value) === "infinite" || Number(value) < 0 ? Animation.Infinite : Math.max(1, Number(value))
  }
  function vectorValue(value) {
    return Array.isArray(value) ? Qt.vector3d(Number(value[0] || 0), Number(value[1] || 0), Number(value[2] || 0)) : value
  }
  function currentAnimation() {
    if (animationType === "number") return numberAnimation
    if (animationType === "color") return colorAnimation
    if (animationType === "rotation") return rotationAnimation
    if (animationType === "vector") return vectorAnimation
    if (animationType === "path") return pathAnimation
    if (animationType === "spring") return springAnimation
    if (animationType === "smoothed") return smoothedAnimation
    if (animationType === "anchor") return anchorAnimation
    if (animationType === "parent") return parentAnimation
    if (animationType === "opacity_animator") return opacityAnimator
    if (animationType === "rotation_animator") return rotationAnimator
    if (animationType === "scale_animator") return scaleAnimator
    if (animationType === "x_animator") return xAnimator
    if (animationType === "y_animator") return yAnimator
    if (animationType === "uniform_animator") return uniformAnimator
    if (animationType === "pause") return pauseAnimation
    return propertyAnimation
  }
  function synchronize(restart) {
    var animation = currentAnimation(); if (!animation || !renderer) return
    requestedRunning = renderer.prop("running", false) === true
    if (renderer.prop("paused", false) === true) { animation.pause(); return }
    if (!requestedRunning) { delayTimer.stop(); animation.stop(); return }
    if (restart || !animation.running) {
      animation.stop()
      var delay = Math.max(0, Number(renderer.prop("delay", 0)))
      if (delay > 0) { delayTimer.interval = delay; delayTimer.restart() } else animation.start()
    } else if (animation.paused) animation.resume()
  }

  Timer { id: delayTimer; repeat: false; onTriggered: if (driver.requestedRunning) driver.currentAnimation().start() }
  Connections {
    target: driver.currentAnimation()
    function onStarted() { driver.send("start", {}) }
    function onStopped() { driver.send("stop", {}) }
    function onFinished() { driver.send("finish", {}) }
    function onRunningChanged() { driver.send("running_change", { value: driver.currentAnimation().running }) }
  }
  Connections { target: renderer; function onNodeChanged() { driver.synchronize(true) } }
  Component.onCompleted: synchronize(false)

  PropertyAnimation { id: propertyAnimation; target: driver.targetItem; property: String(renderer.prop("property", "opacity")); from: renderer.prop("from", 0); to: renderer.prop("to", 1); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue(); alwaysRunToEnd: renderer.prop("always_run", false) === true }
  NumberAnimation { id: numberAnimation; target: driver.targetItem; property: String(renderer.prop("property", "opacity")); from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 1)); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  ColorAnimation { id: colorAnimation; target: driver.targetItem; property: String(renderer.prop("property", "color")); from: renderer.prop("from", "transparent"); to: renderer.prop("to", "white"); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  RotationAnimation { id: rotationAnimation; target: driver.targetItem; property: String(renderer.prop("property", "rotation")); from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 360)); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); direction: { var d=String(renderer.prop("direction","numerical"));if(d==="clockwise")return RotationAnimation.Clockwise;if(d==="counterclockwise")return RotationAnimation.Counterclockwise;if(d==="shortest")return RotationAnimation.Shortest;return RotationAnimation.Numerical } loops: driver.loopsValue() }
  Vector3dAnimation { id: vectorAnimation; target: driver.targetItem; property: String(renderer.prop("property", "scale3d")); from: driver.vectorValue(renderer.prop("from", [0,0,0])); to: driver.vectorValue(renderer.prop("to", [1,1,1])); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  PathAnimation { id: pathAnimation; target: driver.targetItem; duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue(); anchorPoint: Qt.point(Number(renderer.prop("anchor_x", 0)), Number(renderer.prop("anchor_y", 0))); orientation: { var o=String(renderer.prop("orientation","fixed"));if(o==="right_first")return PathAnimation.RightFirst;if(o==="left_first")return PathAnimation.LeftFirst;if(o==="bottom_first")return PathAnimation.BottomFirst;if(o==="top_first")return PathAnimation.TopFirst;return PathAnimation.Fixed } path: Path { PathSvg { path: String(renderer.prop("path", "")) } } }
  SpringAnimation { id: springAnimation; target: driver.targetItem; property: String(renderer.prop("property", "opacity")); from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 1)); spring: Number(renderer.prop("spring", 2)); damping: Number(renderer.prop("damping", 0.2)); epsilon: Number(renderer.prop("epsilon", 0.01)); mass: Number(renderer.prop("mass", 1)); modulus: Number(renderer.prop("modulus", 0)); velocity: Number(renderer.prop("velocity", 0)); loops: driver.loopsValue() }
  SmoothedAnimation { id: smoothedAnimation; target: driver.targetItem; property: String(renderer.prop("property", "opacity")); from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 1)); velocity: Number(renderer.prop("velocity", 200)); duration: Number(renderer.prop("duration", -1)); reversingMode: { var m=String(renderer.prop("reversing_mode","eased"));if(m==="immediate")return SmoothedAnimation.Immediate;if(m==="sync")return SmoothedAnimation.Sync;return SmoothedAnimation.Eased } loops: driver.loopsValue() }
  AnchorAnimation { id: anchorAnimation; targets: driver.targetItem ? [driver.targetItem] : []; duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  ParentAnimation { id: parentAnimation; target: driver.targetItem; newParent: renderer.findRenderedItem(renderer.prop("new_parent", "")); via: renderer.findRenderedItem(renderer.prop("via", "")); loops: driver.loopsValue(); NumberAnimation { properties: "x,y,width,height,scale,rotation"; duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")) } }
  OpacityAnimator { id: opacityAnimator; target: driver.targetItem; from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 1)); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  RotationAnimator { id: rotationAnimator; target: driver.targetItem; from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 360)); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  ScaleAnimator { id: scaleAnimator; target: driver.targetItem; from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 1)); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  XAnimator { id: xAnimator; target: driver.targetItem; from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 100)); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  YAnimator { id: yAnimator; target: driver.targetItem; from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 100)); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  UniformAnimator { id: uniformAnimator; target: driver.targetItem; uniform: String(renderer.prop("uniform", "progress")); from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 1)); duration: Number(renderer.prop("duration", 250)); easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad")); loops: driver.loopsValue() }
  PauseAnimation { id: pauseAnimation; duration: Number(renderer.prop("duration", 0)); loops: driver.loopsValue() }
}
