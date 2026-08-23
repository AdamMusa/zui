import QtQuick
import QtMultimedia

Item {
  id:captureRoot;property var renderer:null;property alias imageCapture:nativeCapture;property int handledCommandRevision:-1
  function quality(){var value=String(renderer?renderer.prop("quality","normal"):"normal");if(value==="very_low")return ImageCapture.VeryLowQuality;if(value==="low")return ImageCapture.LowQuality;if(value==="high")return ImageCapture.HighQuality;if(value==="very_high")return ImageCapture.VeryHighQuality;return ImageCapture.NormalQuality}
  function fileFormat(){var value=String(renderer?renderer.prop("format","unspecified"):"unspecified").toLowerCase();if(value==="jpeg"||value==="jpg")return ImageCapture.JPEG;if(value==="png")return ImageCapture.PNG;if(value==="webp")return ImageCapture.WebP;if(value==="tiff"||value==="tif")return ImageCapture.Tiff;return ImageCapture.UnspecifiedFormat}
  readonly property var sessionItem:renderer?renderer.findRenderedItem(renderer.prop("session","")):null
  function send(name,payload){if(renderer&&renderer.subscribed(name))renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,name,payload||{})}
  function connectSession(){if(sessionItem&&sessionItem.captureSession!==undefined)sessionItem.captureSession.imageCapture=nativeCapture}
  function command(){if(!renderer)return;var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;handledCommandRevision=revision;var value=String(renderer.prop("command",""));if(value==="capture")nativeCapture.capture();else if(value==="save")nativeCapture.captureToFile(renderer.assetUrl(renderer.prop("path","")))}
  ImageCapture{id:nativeCapture;quality:captureRoot.quality();fileFormat:captureRoot.fileFormat();onImageCaptured:function(id,preview){captureRoot.send("captured",{id:id,preview:String(preview)})};onImageSaved:function(id,fileName){captureRoot.send("saved",{id:id,path:fileName})};onErrorOccurred:function(id,error,errorString){renderer.componentError("image_capture_failed",errorString,{capture_id:id,native_code:error})};onReadyForCaptureChanged:captureRoot.send("ready_change",{value:readyForCapture})}
  Component.onCompleted:{connectSession();command()}onSessionItemChanged:connectSession();Connections{target:renderer;function onNodeChanged(){captureRoot.command()}}
}
