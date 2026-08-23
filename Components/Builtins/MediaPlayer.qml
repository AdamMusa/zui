import QtQuick
import QtMultimedia

Item {
  id: playerRoot
  property var renderer: null
  property alias mediaPlayer: nativePlayer
  property alias audioOutput: nativeAudioOutput
  property int handledCommandRevision: -1
  function audioDeviceValid(){var requested=String(renderer?renderer.prop("audio_device",""):"");if(requested==="")return true;var devices=mediaDevices.audioOutputs;for(var index=0;index<devices.length;index++)if(String(devices[index].id)===requested||devices[index].description===requested)return true;if(renderer)renderer.componentError("audio_output_device_not_found","The declared media-player audio output does not exist",{device:requested});return false}
  function audioDevice(){var requested=String(renderer?renderer.prop("audio_device",""):"");var devices=mediaDevices.audioOutputs;if(requested==="")return mediaDevices.defaultAudioOutput;for(var index=0;index<devices.length;index++)if(String(devices[index].id)===requested||devices[index].description===requested)return devices[index];return null}
  function send(name,payload){if(renderer&&renderer.subscribed(name))renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,name,payload||{})}
  function command(){if(!renderer)return;var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;handledCommandRevision=revision;var value=String(renderer.prop("command",renderer.prop("playback","")));if(value==="play")nativePlayer.play();else if(value==="pause")nativePlayer.pause();else if(value==="stop")nativePlayer.stop()}
  MediaDevices{id:mediaDevices}
  AudioOutput { id:nativeAudioOutput;device:playerRoot.audioDevice();volume:playerRoot.audioDeviceValid()?Math.max(0,Math.min(1,Number(renderer?renderer.prop("volume",1):1))):0;muted:!playerRoot.audioDeviceValid()||(renderer&&renderer.prop("muted",false)===true) }
  MediaPlayer {
    id:nativePlayer;source:renderer?renderer.assetUrl(renderer.prop("source","")):"";autoPlay:renderer&&renderer.prop("auto_play",false)===true;loops:Number(renderer?renderer.prop("loops",1):1);playbackRate:Number(renderer?renderer.prop("playback_rate",1):1);position:Number(renderer?renderer.prop("position",0):0);audioOutput:nativeAudioOutput
    onPlaybackStateChanged:{var name=playbackState===MediaPlayer.PlayingState?"play":(playbackState===MediaPlayer.PausedState?"pause":"stop");playerRoot.send(name,{})}
    onMediaStatusChanged:playerRoot.send("media_status",{value:mediaStatus})
    onErrorOccurred:function(error,message){renderer.componentError("media_playback_failed",message,{native_code:error,source:String(source)})}
    onPositionChanged:playerRoot.send("position",{value:position,duration:duration})
    onDurationChanged:playerRoot.send("duration",{value:duration})
    onBufferProgressChanged:playerRoot.send("buffer",{value:bufferProgress})
    onTracksChanged:playerRoot.send("tracks",{audio:audioTracks.length,video:videoTracks.length,subtitles:subtitleTracks.length})
  }
  Component.onCompleted:command();Connections{target:renderer;function onNodeChanged(){playerRoot.command()}}
}
