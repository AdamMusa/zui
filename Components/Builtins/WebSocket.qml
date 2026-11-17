import QtQuick
import QtWebSockets

Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  visible: false
  function statusName(value){return ["connecting","open","closing","closed","error"][Number(value)]||"unknown"}
  function processCommand(){var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;var first=handledCommandRevision<0;handledCommandRevision=revision;if(first&&revision<=0)return;var command=String(renderer.prop("command","send"));if(command==="send")nativeSocket.sendTextMessage(String(renderer.prop("message","")));else if(command==="open")nativeSocket.active=true;else if(command==="close")nativeSocket.active=false}
  WebSocket {
    id: nativeSocket
    url: String(root.renderer.prop("url", ""))
    active: root.renderer.prop("active", true) !== false
    onTextMessageReceived: function(message){renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"message",{value:message})}
    onBinaryMessageReceived: function(message){renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"binary",{value:String(message)})}
    onStatusChanged: {var name=root.statusName(status);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"status",{value:name,native_status:Number(status)});if(name==="error")renderer.componentError("web_socket_failed",errorString,{native_status:Number(status)})}
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"active_change",{value:active})
    onErrorStringChanged: if(errorString!=="")renderer.componentError("web_socket_failed",errorString,{})
  }
  Component.onCompleted: processCommand()
  Connections { target: renderer; function onNodeChanged(){root.processCommand()} }
}
