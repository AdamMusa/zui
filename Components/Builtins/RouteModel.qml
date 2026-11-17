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
  readonly property var featureTypeNames: ({ toll: RouteQuery.TollFeature, highway: RouteQuery.HighwayFeature,
    public_transit: RouteQuery.PublicTransitFeature, ferry: RouteQuery.FerryFeature,
    tunnel: RouteQuery.TunnelFeature, dirt_road: RouteQuery.DirtRoadFeature,
    parks: RouteQuery.ParksFeature, motor_pool_lane: RouteQuery.MotorPoolLaneFeature,
    traffic: RouteQuery.TrafficFeature })
  readonly property var featureWeightNames: ({ neutral: RouteQuery.NeutralFeatureWeight,
    prefer: RouteQuery.PreferFeatureWeight, require: RouteQuery.RequireFeatureWeight,
    avoid: RouteQuery.AvoidFeatureWeight, disallow: RouteQuery.DisallowFeatureWeight })
  readonly property var maneuverDirectionNames: ["no_direction", "forward", "bear_right", "light_right",
    "right", "hard_right", "u_turn_right", "u_turn_left", "hard_left", "left", "light_left", "bear_left"]

  function segmentDetail() {
    return String(renderer.prop("segment_detail", "basic")) === "none"
      ? RouteQuery.NoSegmentData : RouteQuery.BasicSegmentData
  }
  // Without BasicManeuvers the provider returns no turn-by-turn instructions at all, so
  // maneuvers are requested unless the application explicitly opts out.
  function maneuverDetail() {
    return String(renderer.prop("maneuver_detail", "basic")) === "none"
      ? RouteQuery.NoManeuvers : RouteQuery.BasicManeuvers
  }
  function applyFeatureWeights() {
    nativeQuery.resetFeatureWeights()
    var weights = renderer.prop("feature_weights", {}) || {}
    var names = Object.keys(weights).sort()
    for (var index = 0; index < names.length; index++) {
      var feature = names[index]
      var weight = String(weights[feature])
      if (featureTypeNames[feature] === undefined) {
        renderer.componentError("route_feature_unknown", "The routing feature is not a Qt route feature type",
          { feature: feature })
        continue
      }
      if (featureWeightNames[weight] === undefined) {
        renderer.componentError("route_feature_weight_unknown", "The routing feature weight is not a Qt feature weight",
          { feature: feature, weight: weight })
        continue
      }
      nativeQuery.setFeatureWeight(featureTypeNames[feature], featureWeightNames[weight])
    }
  }
  function excludedAreas() {
    var areas = []
    var values = renderer.prop("excluded_areas", []) || []
    for (var index = 0; index < values.length; index++) {
      var value = values[index] || {}
      areas.push(QtPositioning.rectangle(
        QtPositioning.coordinate(Number(value.top_left ? value.top_left.latitude : 0),
                                 Number(value.top_left ? value.top_left.longitude : 0)),
        QtPositioning.coordinate(Number(value.bottom_right ? value.bottom_right.latitude : 0),
                                 Number(value.bottom_right ? value.bottom_right.longitude : 0))))
    }
    return areas
  }
  function coordinatePayload(value) {
    return { latitude: value.latitude, longitude: value.longitude, altitude: value.altitude }
  }
  // RouteManeuver is isCreatable: false - it reaches QML only as a segment's maneuver, so
  // the turn-by-turn instructions are reported as the segment's payload.
  function maneuverPayload(maneuver) {
    if (!maneuver || maneuver.valid !== true) return { valid: false }
    var direction = Number(maneuver.direction)
    return { valid: true, instruction: String(maneuver.instructionText),
      direction: direction,
      direction_name: maneuverDirectionNames[direction] || "no_direction",
      time_to_next: Number(maneuver.timeToNextInstruction),
      distance_to_next: Number(maneuver.distanceToNextInstruction),
      position: coordinatePayload(maneuver.position),
      waypoint: maneuver.waypoint.isValid ? coordinatePayload(maneuver.waypoint) : null,
      extended_attributes: maneuver.extendedAttributes || {} }
  }
  function segmentPayload(route) {
    var segments = []
    var values = route.segments || []
    for (var index = 0; index < values.length; index++) {
      var segment = values[index]
      segments.push({ index: index, distance: Number(segment.distance),
        travel_time: Number(segment.travelTime), path_length: segment.path.length,
        maneuver: maneuverPayload(segment.maneuver) })
    }
    return segments
  }
  function routePath(route){var result=[];for(var index=0;index<route.path.length;index++){var point=route.path[index];result.push({latitude:point.latitude,longitude:point.longitude,altitude:point.altitude})}return result}
  function publish() {
    var values = []
    for (var index = 0; index < nativeModel.count; index++) {
      var route = nativeModel.get(index)
      var bounds = route.bounds
      values.push({ route_id: String(route.routeId), distance: route.distance,
        travel_time: route.travelTime, path: routePath(route),
        leg_index: Number(route.legIndex), leg_count: (route.routeLegs || []).length,
        bounds: bounds && bounds.isValid
          ? { top_left: coordinatePayload(bounds.topLeft), bottom_right: coordinatePayload(bounds.bottomRight) }
          : null,
        segments: segmentPayload(route),
        extended_attributes: route.extendedAttributes || {} })
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "routes",
      { values: values, count: values.length })
  }
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
    segmentDetail: root.segmentDetail()
    maneuverDetail: root.maneuverDetail()
    excludedAreas: root.excludedAreas()
  }
  RouteModel {
    id: nativeModel
    plugin: nativePlugin
    query: nativeQuery
    autoUpdate: root.renderer.prop("auto_update", true) !== false
    onStatusChanged: { var name=root.statusName(status);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"status",{value:name,native_status:Number(status)});if(name==="ready")root.publish() }
    onErrorChanged: if(Number(error)!==0)renderer.componentError("route_failed",errorString,{native_code:Number(error)})
  }
  Component.onCompleted: { configurePlugin();applyFeatureWeights();processCommand() }
  Connections { target: renderer; function onNodeChanged(){root.configurePlugin();root.applyFeatureWeights();root.processCommand()} }
}
