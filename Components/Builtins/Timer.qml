import QtQuick

Item {
  id: timerRoot
  property var renderer: null
  Timer {
    id: nativeTimer
    interval: Math.max(0,Number(renderer?renderer.prop("interval",1000):1000));repeat:renderer&&renderer.prop("repeat",false)===true;running:renderer&&renderer.prop("running",false)===true;triggeredOnStart:renderer&&renderer.prop("triggered_on_start",false)===true
    onTriggered:renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"trigger",{})
    onRunningChanged:renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,running?"start":"stop",{})
  }
  Connections{target:renderer;function onNodeChanged(){if(renderer.prop("restart",false)===true)nativeTimer.restart()}}
}
