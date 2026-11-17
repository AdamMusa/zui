import QtQuick
import QtWebSockets

Item {
  id: root
  required property var renderer
  property var clients: []
  visible: false
  function attach(socket){clients=clients.concat([socket]);socket.textMessageReceived.connect(function(message){renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"message",{value:message,client_url:String(socket.url)})});socket.binaryMessageReceived.connect(function(message){renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"binary",{value:String(message),client_url:String(socket.url)})});renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"client",{url:String(socket.url)})}
  WebSocketServer {
    id: nativeServer
    host: String(root.renderer.prop("host", "0.0.0.0"))
    port: Number(root.renderer.prop("port", 0))
    name: String(root.renderer.prop("name", "Zui"))
    listen: root.renderer.prop("listen", false) === true
    accept: root.renderer.prop("accept", true) !== false
    onClientConnected: function(socket){root.attach(socket)}
    onErrorStringChanged: if(errorString!=="")renderer.componentError("web_socket_server_failed",errorString,{})
    onListenChanged: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"listen_change",{value:listen,host:host,port:port})
    onUrlChanged: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"url_change",{value:String(url)})
  }
}
