import QtQuick
import Qt.labs.lottieqt

LottieAnimation {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  function qualityValue(){var value=String(renderer.prop("quality","high"));if(value==="low")return LottieAnimation.LowQuality;if(value==="medium")return LottieAnimation.MediumQuality;return LottieAnimation.HighQuality}
  function statusName(value){return ["null","loading","ready","error"][Number(value)]||"unknown"}
  function processCommand(){var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;var first=handledCommandRevision<0;handledCommandRevision=revision;if(first&&revision<=0)return;var command=String(renderer.prop("command","play"));var marker=String(renderer.prop("marker",""));var frame=Number(renderer.prop("frame",0));if(command==="play")play();else if(command==="pause")pause();else if(command==="stop")stop();else if(command==="toggle_pause")togglePause();else if(command==="goto_play"){if(marker!=="")gotoAndPlay(marker);else gotoAndPlay(frame)}else if(command==="goto_stop"){if(marker!=="")gotoAndStop(marker);else gotoAndStop(frame)}}
  source: String(renderer.prop("source", ""))
  frameRate: Number(renderer.prop("frame_rate", 60))
  quality: qualityValue()
  autoPlay: renderer.prop("auto_play", true) !== false
  loops: Number(renderer.prop("loops", LottieAnimation.Infinite))
  direction: String(renderer.prop("direction", "forward")) === "reverse" ? LottieAnimation.Reverse : LottieAnimation.Forward
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 240))
  visible: renderer.prop("visible", true) !== false
  onStatusChanged: {var name=statusName(status);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"status",{value:name,native_status:Number(status),start_frame:startFrame,end_frame:endFrame,duration:getDuration()});if(name==="error")renderer.componentError("lottie_load_failed","The Lottie animation could not be loaded",{source:String(source)})}
  onFinished: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"finished",{})
  Component.onCompleted: processCommand()
  Connections { target: renderer; function onNodeChanged(){root.processCommand()} }
}
