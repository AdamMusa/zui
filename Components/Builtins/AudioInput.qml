import QtQuick
import QtMultimedia

Item {
  id:inputRoot;property var renderer:null;property alias audioInput:nativeInput
  function deviceValid(){var requested=String(renderer?renderer.prop("device",""):"");if(requested==="")return true;var list=nativeDevices.audioInputs;for(var index=0;index<list.length;index++)if(String(list[index].id)===requested||list[index].description===requested)return true;if(renderer)renderer.componentError("audio_input_device_not_found","The declared audio input device does not exist",{device:requested});return false}
  function device(){var requested=String(renderer?renderer.prop("device",""):"");var list=nativeDevices.audioInputs;if(requested==="")return nativeDevices.defaultAudioInput;for(var index=0;index<list.length;index++)if(String(list[index].id)===requested||list[index].description===requested)return list[index];return null}
  MediaDevices{id:nativeDevices}
  AudioInput{id:nativeInput;device:inputRoot.device();muted:!inputRoot.deviceValid()||(renderer&&renderer.prop("muted",false)===true);volume:inputRoot.deviceValid()?Math.max(0,Math.min(1,Number(renderer?renderer.prop("volume",1):1))):0;onMutedChanged:if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"muted_change",{value:muted});onVolumeChanged:if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"volume_change",{value:volume});onDeviceChanged:if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"device_change",{description:device.description,id:String(device.id)})}
}
