import QtQuick

// One Ruby node of a Qt Quick 3D scene.
//
// A branch is the `renderer` a 3D adapter reads through, so it answers the same
// questions ControlNode answers for the two-dimensional tree: the node's props
// and event subscriptions, the bridge to send events over, and the error
// channel. It loads the adapter for its node type, attaches the created object
// to its 3D parent, publishes it to the scene registry so other nodes can refer
// to it by id, and recurses into its own children.
Item {
    id: branch

    // Renderer facade of the owning node: the View3D adapter at the top of a
    // scene, the parent branch below it.
    property var host: null
    // The Scene3dChildren that created this branch, notified when the object
    // this branch owns appears or disappears.
    property var owner: null
    // The Qt Quick 3D object this branch's object is attached to.
    property var target: null
    property string controlId: ""
    property int repeatIndex: 0

    property var node: null
    property string lastComponentErrorKey: ""
    readonly property var bridge: host ? host.bridge : null
    readonly property string surfaceName: host ? String(host.surfaceName) : ""
    readonly property color foreground: host ? host.foreground : "#ffffff"
    readonly property string fontFamily: host ? String(host.fontFamily) : ""
    readonly property int renderDepth: host && host.renderDepth !== undefined ? host.renderDepth + 1 : 1
    readonly property var object3d: adapterLoader.item
    // Adapters that keep their children somewhere other than themselves, such
    // as a repeater that replicates them across generated nodes, say so here.
    readonly property var childTargets: {
        if (!object3d)
            return []
        if (object3d.hasOwnProperty("sceneChildHosts") && Array.isArray(object3d.sceneChildHosts))
            return object3d.sceneChildHosts
        if (object3d.hasOwnProperty("sceneChildHost") && object3d.sceneChildHost)
            return [object3d.sceneChildHost]
        return [object3d]
    }
    readonly property var childNodes: node && Array.isArray(node.children) ? node.children : []

    function adapterName(typeName) {
        var parts = String(typeName || "").split("_")
        for (var index = 0; index < parts.length; index++)
            parts[index] = parts[index].charAt(0).toUpperCase() + parts[index].slice(1)
        return parts.join("")
    }

    function prop(name, fallback) {
        var props = node && node.props ? node.props : null
        var value = props ? props[name] : undefined
        return value === undefined || value === null ? fallback : value
    }

    function hasProp(name) {
        var props = node && node.props ? node.props : null
        return props !== null && props[name] !== undefined && props[name] !== null
    }

    function subscribed(eventName) {
        return node !== null && Array.isArray(node.events) && node.events.indexOf(eventName) >= 0
    }

    function assetUrl(value) {
        return host ? host.assetUrl(value) : ""
    }

    function emitEvent(eventName, payload) {
        if (!bridge || !subscribed(eventName))
            return
        bridge.sendEvent(surfaceName, controlId, eventName, payload || ({}))
    }

    function componentError(code, message, payload) {
        var componentType = node ? String(node.type) : "component"
        var errorCode = String(code || "component_error")
        var errorMessage = String(message || "Component failed")
        var errorKey = componentType + ":" + errorCode + ":" + errorMessage
        if (errorKey === lastComponentErrorKey)
            return
        lastComponentErrorKey = errorKey
        if (bridge && bridge.reportComponentError)
            bridge.reportComponentError(surfaceName, controlId, componentType, errorCode, errorMessage)
        if (!subscribed("error"))
            return
        var eventPayload = payload && typeof payload === "object" ? payload : ({})
        eventPayload.code = errorCode
        eventPayload.message = errorMessage
        bridge.sendEvent(surfaceName, controlId, "error", eventPayload)
    }

    function registerSceneObject(objectId, object) {
        if (host && host.registerSceneObject)
            host.registerSceneObject(objectId, object)
    }

    function sceneObject(objectId) {
        return host && host.sceneObject ? host.sceneObject(objectId) : null
    }

    function sceneObjects(objectIds) {
        return host && host.sceneObjects ? host.sceneObjects(objectIds) : []
    }

    function sceneObjectId(object) {
        return host && host.sceneObjectId ? host.sceneObjectId(object) : ""
    }

    function childObjects(types) {
        return childHost.objectsOfType(types)
    }

    function childObject(types) {
        return childHost.objectOfType(types)
    }

    function childObjectsAndReferences(types, referenceProperty) {
        return childObjects(types).concat(sceneObjects(prop(referenceProperty, [])))
    }

    function childObjectOrReference(types, referenceProperty) {
        var declared = childObject(types)
        if (declared)
            return declared
        var referenced = sceneObjects(prop(referenceProperty, []))
        return referenced.length > 0 ? referenced[0] : null
    }

    function synchronizeNode() {
        var nextNode = bridge ? bridge.nodeFor(controlId) : null
        if (node !== nextNode)
            node = nextNode
    }

    function attachObject() {
        var object = adapterLoader.item
        if (!object)
            return
        if (target) {
            object.parent = target
            if (object.parent !== target) {
                componentError("scene3d_attach_failed",
                               "A " + (node ? node.type : "component")
                               + " cannot be attached to a Qt Quick 3D scene",
                               { "parent": String(target) })
                return
            }
        }
        registerSceneObject(controlId, object)
        if (owner)
            owner.noteRevision()
        if (subscribed("mount"))
            emitEvent("mount", {})
    }

    visible: false
    width: 0
    height: 0
    onBridgeChanged: synchronizeNode()
    onControlIdChanged: synchronizeNode()
    Component.onCompleted: synchronizeNode()
    Component.onDestruction: {
        registerSceneObject(controlId, null)
        if (owner)
            owner.removeBranch(branch)
        if (subscribed("unmount"))
            emitEvent("unmount", {})
    }

    Connections {
        target: branch.bridge
        function onRevisionChanged() {
            branch.synchronizeNode()
        }
    }

    Loader {
        id: adapterLoader

        asynchronous: false
        onLoaded: branch.attachObject()
        onStatusChanged: {
            if (status === Loader.Error) {
                branch.componentError("component_load_failed",
                                      "Unable to load the declared "
                                      + (branch.node ? branch.node.type : "component") + " renderer",
                                      { "source": String(source) })
            }
        }
    }

    Scene3dChildren {
        id: childHost

        host: branch
        targets: branch.childTargets
        nodes: branch.childNodes
    }

    onNodeChanged: {
        if (!node) {
            if (adapterLoader.source !== "")
                adapterLoader.source = ""
            return
        }
        var wanted = Qt.resolvedUrl("../" + adapterName(node.type) + ".qml")
        if (String(adapterLoader.source) === String(wanted))
            return
        lastComponentErrorKey = ""
        adapterLoader.setSource(wanted, { "renderer": branch })
    }
}
