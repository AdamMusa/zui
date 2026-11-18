import QtQuick
import QtQuick.Timeline

// QtQuick.Timeline/Keyframe. One value a property holds at one frame, with the
// easing used to reach it from the previous keyframe.
//
// A keyframe_group references its keyframes by control id and reads
// `nativeKeyframe` from each.
Item {
  id: keyframeRoot
  property var renderer: null
  readonly property var nativeKeyframe: nativeFrame

  Keyframe {
    id: nativeFrame
    frame: Number(keyframeRoot.renderer ? keyframeRoot.renderer.prop("frame", 0) : 0)
    value: keyframeRoot.renderer ? keyframeRoot.renderer.prop("value", 0) : 0
    easing.type: keyframeRoot.renderer
      ? keyframeRoot.renderer.easingType(keyframeRoot.renderer.prop("easing", "linear"))
      : Easing.Linear
  }
}
