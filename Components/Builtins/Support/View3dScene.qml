import QtQuick
import QtQuick3D
import "Value3d.js" as Value3d

// The live Qt Quick 3D viewport behind view_3d.
//
// Child nodes declared in Ruby become Qt Quick 3D objects attached to this
// view's scene root. A camera, scene environment or fog declared among them is
// adopted by the view; everything else stays where it was declared. Nodes can
// also be addressed by their Ruby id, which is how a model refers to a material
// or a geometry that lives elsewhere in the scene.
Item {
    id: view3dRoot

    required property var renderer

    readonly property var bridge: renderer.bridge
    readonly property string surfaceName: String(renderer.surfaceName)
    readonly property color foreground: renderer.foreground
    readonly property string fontFamily: String(renderer.fontFamily)
    readonly property int renderDepth: renderer.renderDepth

    // The viewport a plain QObject helper is created under, and the item a
    // camera controller sits over to read pointer and key input.
    readonly property var viewport: nativeView
    readonly property var itemHost: controllerHost

    readonly property var cameraTypes: ["perspective_camera", "orthographic_camera",
        "frustum_camera", "custom_camera"]
    readonly property var environmentTypes: ["scene_environment", "extended_scene_environment"]

    // Scene registry. Every branch publishes the object it owns so that nodes
    // can refer to one another by their Ruby id instead of by nesting.
    property var sceneRegistry: ({})
    property int sceneRegistryRevision: 0

    function registerSceneObject(objectId, object) {
        var key = String(objectId || "")
        if (key === "")
            return
        if (object === null || object === undefined)
            delete sceneRegistry[key]
        else
            sceneRegistry[key] = object
        sceneRegistryRevision += 1
    }

    function sceneObject(objectId) {
        var tracked = view3dRoot.sceneRegistryRevision
        var key = String(objectId === undefined || objectId === null ? "" : objectId)
        return key !== "" && sceneRegistry.hasOwnProperty(key) ? sceneRegistry[key] : null
    }

    function sceneObjects(objectIds) {
        var names = Value3d.identifiers(objectIds)
        var objects = []
        for (var index = 0; index < names.length; index++) {
            var object = sceneObject(names[index])
            if (object)
                objects.push(object)
        }
        return objects
    }

    function sceneObjectId(object) {
        var tracked = view3dRoot.sceneRegistryRevision
        if (!object)
            return ""
        for (var key in sceneRegistry) {
            if (sceneRegistry[key] === object)
                return key
        }
        return ""
    }

    function assetUrl(value) {
        return renderer.assetUrl(value)
    }

    function findRenderedItem(targetId) {
        var name = String(targetId === undefined || targetId === null ? "" : targetId)
        return name === "" ? null : renderer.findRenderedItem(name)
    }

    function componentError(code, message, payload) {
        renderer.componentError(code, message, payload)
    }

    function pickPayload(result, x, y) {
        return {
            "x": x,
            "y": y,
            "hit": result.objectHit !== null,
            "object_id": view3dRoot.sceneObjectId(result.objectHit),
            "distance": Number(result.distance),
            "instance_index": Number(result.instanceIndex),
            "scene_position": [result.scenePosition.x, result.scenePosition.y, result.scenePosition.z],
            "position": [result.position.x, result.position.y, result.position.z],
            "normal": [result.normal.x, result.normal.y, result.normal.z],
            "uv": [result.uvPosition.x, result.uvPosition.y]
        }
    }

    function reportPick(x, y) {
        if (!renderer.subscribed("pick"))
            return
        var result = nativeView.pick(x, y)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "pick",
                                  view3dRoot.pickPayload(result, x, y))
    }

    implicitWidth: Number(renderer.prop("width", 420))
    implicitHeight: Number(renderer.prop("height", 420))
    clip: true

    View3D {
        id: nativeView

        anchors.fill: parent
        camera: topLevelChildren.objectOfType(view3dRoot.cameraTypes)
            || view3dRoot.sceneObject(renderer.prop("camera", ""))
        environment: topLevelChildren.objectOfType(view3dRoot.environmentTypes)
            || view3dRoot.sceneObject(renderer.prop("environment", ""))
        importScene: view3dRoot.sceneObject(renderer.prop("import_scene", ""))
        explicitTextureWidth: Number(renderer.prop("texture_width", 0))
        explicitTextureHeight: Number(renderer.prop("texture_height", 0))
        renderMode: Value3d.enumeration(renderer.prop("render_mode", "offscreen"), {
            "offscreen": View3D.Offscreen,
            "underlay": View3D.Underlay,
            "overlay": View3D.Overlay,
            "inline": View3D.Inline
        }, View3D.Offscreen)
        renderFormat: Value3d.enumeration(renderer.prop("render_format", "rgba8"), {
            "rgba8": ShaderEffectSource.RGBA8,
            "rgba16f": ShaderEffectSource.RGBA16F,
            "rgba32f": ShaderEffectSource.RGBA32F
        }, ShaderEffectSource.RGBA8)

        Node {
            id: sceneRoot
        }
    }

    Item {
        id: controllerHost

        anchors.fill: parent
    }

    Scene3dChildren {
        id: topLevelChildren

        host: view3dRoot
        targets: [sceneRoot]
        nodes: renderer.node && Array.isArray(renderer.node.children) ? renderer.node.children : []
    }

    TapHandler {
        enabled: renderer.subscribed("click") || renderer.subscribed("pick")
        gesturePolicy: TapHandler.DragThreshold
        onTapped: function(eventPoint) {
            if (renderer.subscribed("click")) {
                renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {
                    "x": eventPoint.position.x,
                    "y": eventPoint.position.y
                })
            }
            view3dRoot.reportPick(eventPoint.position.x, eventPoint.position.y)
        }
    }
}
