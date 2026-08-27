import QtQuick
import QtLocation
import QtPositioning

Item {
  id: root
  required property var renderer
  property var parameterObjects: []
  property int handledCommandRevision: -1
  visible: false
  function queryValue() {
    var value=renderer.prop("query", "")
    if(value&&typeof value==="object"&&value.latitude!==undefined)return QtPositioning.coordinate(Number(value.latitude),Number(value.longitude),Number(value.altitude||0))
    return value
  }
  function configurePlugin() {
    for(var oldIndex=0;oldIndex<parameterObjects.length;oldIndex++)parameterObjects[oldIndex].destroy()
    var objects=[];var values=renderer.prop("plugin_parameters",{})||{};var names=Object.keys(values).sort()
    for(var index=0;index<names.length;index++)objects.push(parameterComponent.createObject(root,{name:names[index],value:values[names[index]]}))
    parameterObjects=objects;nativePlugin.parameters=objects;nativePlugin.name=String(renderer.prop("plugin","osm"))
  }
  function statusName(value){return ["null","ready","loading","error"][Number(value)]||"unknown"}
  function publish() {
    var values=[]
    for(var index=0;index<nativeModel.count;index++){
      var location=nativeModel.get(index);var coordinate=location.coordinate;var address=location.address
      values.push({latitude:coordinate.latitude,longitude:coordinate.longitude,altitude:coordinate.altitude,
        address:{text:address.text,country:address.country,country_code:address.countryCode,state:address.state,
          county:address.county,city:address.city,district:address.district,postal_code:address.postalCode,street:address.street}})
    }
    renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"results",{values:values,count:values.length})
  }
  function processCommand(){var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;var first=handledCommandRevision<0;handledCommandRevision=revision;if(first&&revision<=0)return;var command=String(renderer.prop("command","update"));if(command==="cancel")nativeModel.cancel();else if(command==="reset")nativeModel.reset();else nativeModel.update()}
  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  GeocodeModel {
    id: nativeModel
    plugin: nativePlugin
    query: root.queryValue()
    limit: Number(root.renderer.prop("limit", -1))
    offset: Number(root.renderer.prop("offset", 0))
    autoUpdate: root.renderer.prop("auto_update", true) !== false
    onStatusChanged: { var name=root.statusName(status);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"status",{value:name,native_status:Number(status)});if(name==="ready")root.publish() }
    onErrorChanged: if(Number(error)!==0)renderer.componentError("geocode_failed",errorString,{native_code:Number(error)})
  }
  Component.onCompleted: { configurePlugin();processCommand() }
  Connections { target: renderer; function onNodeChanged(){root.configurePlugin();root.processCommand()} }
}
