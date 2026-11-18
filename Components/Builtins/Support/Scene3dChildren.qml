import QtQuick

// Instantiates the Ruby child nodes of one Qt Quick 3D object.
//
// ControlNode drives the two-dimensional item tree, and a Qt Quick 3D object is
// not an Item, so it cannot be a Loader's visual child. This host keeps the
// per-node bookkeeping in a hidden item tree that mirrors the scene graph while
// the objects themselves are attached to their 3D parent. A branch is loaded
// through its resolved URL so the recursion is created at runtime instead of
// becoming a circular QML type reference.
Item {
    id: children3d

    // Renderer facade the branches read their node, bridge and events from.
    required property var host
    // The 3D objects each declared child subtree is attached to. More than one
    // target replicates the subtree, which is how repeater_3d repeats it.
    property var targets: []
    property var nodes: []
    // Branches that have published themselves, in declaration order.
    property var branches: []
    // Bumped whenever a branch publishes or withdraws its object so that
    // bindings calling objectsOfType() re-evaluate.
    property int revision: 0

    readonly property var placements: {
        var list = []
        var declaredTargets = Array.isArray(targets) ? targets : [targets]
        var declaredNodes = Array.isArray(nodes) ? nodes : []
        for (var targetIndex = 0; targetIndex < declaredTargets.length; targetIndex++) {
            if (!declaredTargets[targetIndex])
                continue
            for (var nodeIndex = 0; nodeIndex < declaredNodes.length; nodeIndex++) {
                if (!declaredNodes[nodeIndex])
                    continue
                list.push({
                    "target": declaredTargets[targetIndex],
                    "node": declaredNodes[nodeIndex],
                    "repeatIndex": targetIndex
                })
            }
        }
        return list
    }

    function addBranch(branch) {
        var list = branches.slice()
        list.push(branch)
        branches = list
        revision += 1
    }

    function removeBranch(branch) {
        var list = []
        for (var index = 0; index < branches.length; index++) {
            if (branches[index] !== branch)
                list.push(branches[index])
        }
        branches = list
        revision += 1
    }

    function allObjects() {
        var objects = []
        for (var index = 0; index < branches.length; index++) {
            if (branches[index].object3d)
                objects.push(branches[index].object3d)
        }
        return objects
    }

    function objectsOfType(types) {
        var tracked = children3d.revision
        var objects = []
        for (var index = 0; index < branches.length; index++) {
            var branch = branches[index]
            if (!branch.object3d || !branch.node)
                continue
            if (types.indexOf(String(branch.node.type)) >= 0)
                objects.push(branch.object3d)
        }
        return objects
    }

    function objectOfType(types) {
        var objects = objectsOfType(types)
        return objects.length > 0 ? objects[0] : null
    }

    function noteRevision() {
        children3d.revision += 1
    }

    visible: false
    width: 0
    height: 0

    Repeater {
        id: placementRepeater

        model: children3d.placements
        delegate: Loader {
            required property var modelData

            source: Qt.resolvedUrl("Scene3dBranch.qml")
            onLoaded: {
                item.host = children3d.host
                item.owner = children3d
                item.target = modelData.target
                item.repeatIndex = Number(modelData.repeatIndex)
                item.controlId = String(modelData.node.id)
                children3d.addBranch(item)
            }
        }
    }
}
