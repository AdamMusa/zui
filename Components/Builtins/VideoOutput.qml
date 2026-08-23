import QtQuick
import QtMultimedia

VideoOutput {
  id: videoRoot
  property var renderer: null
  readonly property var sourceItem: renderer ? renderer.findRenderedItem(renderer.prop("source", "")) : null
  implicitWidth:Number(renderer?renderer.prop("width",640):640);implicitHeight:Number(renderer?renderer.prop("height",360):360)
  fillMode:{var mode=String(renderer?renderer.prop("fill_mode","contain"):"contain");if(mode==="cover")return VideoOutput.PreserveAspectCrop;if(mode==="stretch")return VideoOutput.Stretch;return VideoOutput.PreserveAspectFit}
  orientation:Number(renderer?renderer.prop("orientation",0):0);mirrored:renderer&&renderer.prop("mirrored",false)===true
  endOfStreamPolicy:String(renderer?renderer.prop("end_of_stream_policy","clear"):"clear")==="keep"?VideoOutput.KeepLastFrame:VideoOutput.ClearOutput
  function connectSource(){if(!sourceItem)return;if(sourceItem.mediaPlayer!==undefined)sourceItem.mediaPlayer.videoOutput=videoRoot;else if(sourceItem.captureSession!==undefined)sourceItem.captureSession.videoOutput=videoRoot;renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"source_change",{value:renderer.prop("source","")})}
  Component.onCompleted:connectSource();onSourceItemChanged:connectSource()
  Connections{target:videoSink;function onVideoFrameChanged(){if(renderer.subscribed("frame"))renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"frame",{})}}
}
