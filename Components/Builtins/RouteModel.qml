import QtQuick
import QtLocation
import QtPositioning

Item {
  id: root
  required property var renderer
  property var parameterObjects: []
  property int handledCommandRevision: -1
  visible: false
  function coordinates(values){var result=[];values=values||[];for(var index=0;index<values.length;index++){var value=values[index]||{};result.push(QtPositioning.coordinate(Number(value.latitude||0),Number(value.longitude||0),Number(value.altitude||0)))}return result}
  function configurePlugin(){for(var oldIndex=0;oldIndex<parameterObjects.length;oldIndex++)parameterObjects[oldIndex].destroy();var objects=[];var values=renderer.prop("plugin_parameters",{})||{};var names=Object.keys(values).sort();for(var index=0;index<names.length;index++)objects.push(parameterComponent.createObject(root,{name:names[index],value:values[names[index]]}));parameterObjects=objects;nativePlugin.parameters=objects;nativePlugin.name=String(renderer.prop("plugin","osm"))}
  function travelMode(){var value=String(renderer.prop("travel_mode","car"));if(value==="pedestrian")return RouteQuery.PedestrianTravel;if(value==="bicycle")return RouteQuery.BicycleTravel;if(value==="public_transit")return RouteQuery.PublicTransitTravel;if(value==="truck")return RouteQuery.TruckTravel;return RouteQuery.CarTravel}
  function optimization(){var value=String(renderer.prop("optimization","fastest"));if(value==="shortest")return RouteQuery.ShortestRoute;if(value==="economic")return RouteQuery.MostEconomicRoute;if(value==="scenic")return RouteQuery.MostScenicRoute;return RouteQuery.FastestRoute}
  function statusName(value){return ["null","ready","loading","error"][Number(value)]||"unknown"}
  function routePath(route){var result=[];for(var index=0;index<route.path.length;index++){var point=route.path[index];result.push({latitude:point.latitude,longitude:point.longitude,altitude:point.altitude})}return result}
  function publish(){var values=[];for(var index=0;index<nativeModel.count;index++){var route=nativeModel.get(index);values.push({distance:route.distance,travel_time:route.travelTime,path:routePath(route)})}renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"routes",{values:values,count:values.length})}
  function processCommand(){var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;var first=handledCommandRevision<0;handledCommandRevision=revision;if(first&&revision<=0)return;var command=String(renderer.prop("command","update"));if(command==="cancel")nativeModel.cancel();else if(command==="reset")nativeModel.reset();else nativeModel.update()}
  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  RouteQuery {
    id: nativeQuery
    waypoints: root.coordinates(root.renderer.prop("waypoints", []))
    travelModes: root.travelMode()
    routeOptimizations: root.optimization()
    numberAlternativeRoutes: Number(root.renderer.prop("alternatives", 0))
    departureTime: String(root.renderer.prop("departure_time", ""))
  }
  RouteModel {
    id: nativeModel
    plugin: nativePlugin
    query: nativeQuery
    autoUpdate: root.renderer.prop("auto_update", true) !== false
    onStatusChanged: { var name=root.statusName(status);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"status",{value:name,native_status:Number(status)});if(name==="ready")root.publish() }
    onErrorChanged: if(Number(error)!==0)renderer.componentError("route_failed",errorString,{native_code:Number(error)})
  }
  Component.onCompleted: { configurePlugin();processCommand() }
  Connections { target: renderer; function onNodeChanged(){root.configurePlugin();root.processCommand()} }
}
