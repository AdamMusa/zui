import QtQuick
import QtMultimedia

Item {
  id:soundRoot;property var renderer:null;property alias soundEffect:nativeSound;property int handledCommandRevision:-1
  function send(name,payload){if(renderer&&renderer.subscribed(name))renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,name,payload||{})}
  function command(){if(!renderer)return;var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;handledCommandRevision=revision;var value=String(renderer.prop("command",renderer.prop("playback","")));if(value==="play")nativeSound.play();else if(value==="stop")nativeSound.stop()}
  SoundEffect{id:nativeSound;source:renderer?renderer.assetUrl(renderer.prop("source","")):"";loops:Number(renderer?renderer.prop("loops",1):1);volume:Math.max(0,Math.min(1,Number(renderer?renderer.prop("volume",1):1)));muted:renderer&&renderer.prop("muted",false)===true;onPlayingChanged:soundRoot.send(playing?"play":"stop",{});onStatusChanged:{soundRoot.send("status",{value:status});if(status===SoundEffect.Error)renderer.componentError("sound_effect_load_failed","Unable to load the declared sound effect",{source:String(source)})}onLoopsRemainingChanged:soundRoot.send("loops_remaining",{value:loopsRemaining})}
  Component.onCompleted:command();Connections{target:renderer;function onNodeChanged(){soundRoot.command()}}
}
