import QtQuick
import QtMultimedia as Multimedia

Item {
  id:captureRoot;property var renderer:null;property alias imageCapture:nativeCapture;property int handledCommandRevision:-1
  function quality(){var value=String(renderer?renderer.prop("quality","normal"):"normal");if(value==="very_low")return Multimedia.ImageCapture.VeryLowQuality;if(value==="low")return Multimedia.ImageCapture.LowQuality;if(value==="high")return Multimedia.ImageCapture.HighQuality;if(value==="very_high")return Multimedia.ImageCapture.VeryHighQuality;return Multimedia.ImageCapture.NormalQuality}
  function fileFormat(){var value=String(renderer?renderer.prop("format","unspecified"):"unspecified").toLowerCase();if(value==="jpeg"||value==="jpg")return Multimedia.ImageCapture.JPEG;if(value==="png")return Multimedia.ImageCapture.PNG;if(value==="webp")return Multimedia.ImageCapture.WebP;if(value==="tiff"||value==="tif")return Multimedia.ImageCapture.Tiff;return Multimedia.ImageCapture.UnspecifiedFormat}
  readonly property var sessionItem:renderer?renderer.findRenderedItem(renderer.prop("session","")):null
  function send(name,payload){if(renderer&&renderer.subscribed(name))renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,name,payload||{})}
  function connectSession(){if(sessionItem&&sessionItem.captureSession!==undefined)sessionItem.captureSession.imageCapture=nativeCapture}
  function command(){if(!renderer)return;var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;handledCommandRevision=revision;var value=String(renderer.prop("command",""));if(value==="capture")nativeCapture.capture();else if(value==="save")nativeCapture.captureToFile(renderer.assetUrl(renderer.prop("path","")))}
  Multimedia.ImageCapture{id:nativeCapture;quality:captureRoot.quality();fileFormat:captureRoot.fileFormat();onImageCaptured:function(id,preview){captureRoot.send("captured",{id:id,preview:String(preview)})};onImageSaved:function(id,fileName){captureRoot.send("saved",{id:id,path:fileName})};onErrorOccurred:function(id,error,errorString){renderer.componentError("image_capture_failed",errorString,{capture_id:id,native_code:error})};onReadyForCaptureChanged:captureRoot.send("ready_change",{value:readyForCapture})}
  Component.onCompleted:{connectSession();command()}onSessionItemChanged:connectSession();Connections{target:renderer;function onNodeChanged(){captureRoot.command()}}
}
