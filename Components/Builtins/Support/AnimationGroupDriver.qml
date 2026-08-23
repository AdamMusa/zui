import QtQuick

Item {
  id: groupRoot
  required property var renderer
  required property bool sequential
  property var createdAnimations: []

  function factoryFor(type) { if(type==="color")return colorFactory;if(type==="pause")return pauseFactory;if(type==="rotation")return rotationFactory;return numberFactory }
  function rebuild() {
    nativeGroup.stop(); for(var oldIndex=0;oldIndex<createdAnimations.length;oldIndex++)createdAnimations[oldIndex].destroy();createdAnimations=[]
    var definitions=renderer.prop("animations",[]);if(!Array.isArray(definitions))return
    for(var index=0;index<definitions.length;index++){
      var definition=definitions[index]||{};var type=String(definition.type||"number");var properties={duration:Number(definition.duration||250)}
      if(type!=="pause"){properties.target=renderer.findRenderedItem(definition.target||renderer.prop("target",""));properties.property=String(definition.property||"opacity");properties.from=definition.from===undefined?0:definition.from;properties.to=definition.to===undefined?1:definition.to}
      var object=factoryFor(type).createObject(nativeGroup,properties)
      nativeGroup.animations.push(object);createdAnimations.push(object)
    }
    nativeGroup.loops=String(renderer.prop("loops",1))==="infinite"?Animation.Infinite:Math.max(1,Number(renderer.prop("loops",1)))
    if(renderer.prop("running",false)===true){nativeGroup.start();if(renderer.prop("paused",false)===true)nativeGroup.pause()}
  }
  function send(name,payload){if(renderer.subscribed(name))renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,name,payload||{})}
  Component { id:numberFactory; NumberAnimation{} }
  Component { id:colorFactory; ColorAnimation{} }
  Component { id:rotationFactory; RotationAnimation{} }
  Component { id:pauseFactory; PauseAnimation{} }
  ParallelAnimation { id:parallelGroup; onStarted:groupRoot.send("start",{});onStopped:groupRoot.send("stop",{});onFinished:groupRoot.send("finish",{}) }
  SequentialAnimation { id:sequentialGroup; onStarted:groupRoot.send("start",{});onStopped:groupRoot.send("stop",{});onFinished:groupRoot.send("finish",{}) }
  readonly property var nativeGroup: sequential ? sequentialGroup : parallelGroup
  Connections{target:renderer;function onNodeChanged(){groupRoot.rebuild()}}
  Component.onCompleted:rebuild()
}
