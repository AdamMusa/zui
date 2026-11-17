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
    property string instantiatedType: ""
    property string lastComponentErrorKey: ""
    readonly property var bridge: host ? host.bridge : null
    readonly property string surfaceName: host ? String(host.surfaceName) : ""
    readonly property color foreground: host ? host.foreground : "#ffffff"
    readonly property string fontFamily: host ? String(host.fontFamily) : ""
    readonly property int renderDepth: host && host.renderDepth !== undefined ? host.renderDepth + 1 : 1
    // The object this branch owns. It is created rather than loaded so that its
    // QML parent can be chosen per kind, which a Loader cannot do.
    property var object3d: null
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

    // The nearest enclosing object of one of the given types. Qt Quick 3D has
    // several properties that name an owner a node is already declared inside,
    // such as a particle's system, and repeating that name in Ruby would be
    // noise.
    function ancestorObject(types) {
        var current = host
        while (current) {
            if (current.node && current.object3d
                && types.indexOf(String(current.node.type)) >= 0)
                return current.object3d
            current = current.host ? current.host : null
        }
        return null
    }

    function ownerOrReference(types, referenceProperty) {
        var referenced = sceneObjects(prop(referenceProperty, []))
        return referenced.length > 0 ? referenced[0] : ancestorObject(types)
    }

    // The viewport this node belongs to, which is what a debug overlay reports
    // on when no other view is named.
    function viewport() {
        return host && host.viewport ? host.viewport : null
    }

    // Reaches a two-dimensional Zui control by its Ruby id, which is how a
    // texture takes a live Qt Quick item as its source.
    function findRenderedItem(targetId) {
        return host && host.findRenderedItem ? host.findRenderedItem(targetId) : null
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

    // Not everything in the Qt Quick 3D surface is a scene object. A camera
    // controller is a Qt Quick Item that reads pointer and key input over the
    // viewport, and a helper such as InfiniteGrid is a plain QObject that finds
    // the viewport it belongs to through its QML parent. Each kind is placed
    // where Qt expects to find it.
    function creationParent() {
        if (target)
            return target
        return host && host.viewport ? host.viewport : branch
    }

    function attachObject() {
        var object = object3d
        if (!object)
            return
        if (object.hasOwnProperty("anchors")) {
            var itemHost = host && host.itemHost ? host.itemHost : null
            if (!itemHost) {
                componentError("scene3d_attach_failed",
                               "A " + (node ? node.type : "component")
                               + " needs a viewport to sit over", {})
                return
            }
            object.parent = itemHost
            object.anchors.fill = itemHost
        } else if (target && object.hasOwnProperty("parent")) {
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

    function releaseObject() {
        if (!object3d)
            return
        registerSceneObject(controlId, null)
        var released = object3d
        object3d = null
        if (owner)
            owner.noteRevision()
        released.destroy()
    }

    function instantiate() {
        releaseObject()
        if (!node)
            return
        var url = Qt.resolvedUrl("../" + adapterName(node.type) + ".qml")
        var component = Qt.createComponent(url, Component.PreferSynchronous)
        if (component.status === Component.Error) {
            componentError("component_load_failed", component.errorString(), { "source": String(url) })
            return
        }
        var created = component.createObject(creationParent(), { "renderer": branch })
        if (!created) {
            componentError("component_load_failed",
                           "Unable to create the declared "
                           + (node ? node.type : "component") + " renderer",
                           { "source": String(url) })
            return
        }
        object3d = created
        attachObject()
    }

    visible: false
    width: 0
    height: 0
    onBridgeChanged: synchronizeNode()
    onControlIdChanged: synchronizeNode()
    Component.onCompleted: synchronizeNode()
    Component.onDestruction: {
        if (subscribed("unmount"))
            emitEvent("unmount", {})
        releaseObject()
        if (owner)
            owner.removeBranch(branch)
    }

    Connections {
        target: branch.bridge
        function onRevisionChanged() {
            branch.synchronizeNode()
        }
    }

    Scene3dChildren {
        id: childHost

        host: branch
        targets: branch.childTargets
        nodes: branch.childNodes
    }

    // Reactive patches keep the node type, so the object is only rebuilt when
    // the type actually changes; its own bindings carry every other change.
    onNodeChanged: {
        var wanted = node ? String(node.type) : ""
        if (wanted === instantiatedType)
            return
        instantiatedType = wanted
        lastComponentErrorKey = ""
        instantiate()
    }
}
