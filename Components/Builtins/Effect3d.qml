import QtQuick
import QtQuick3D
import "Support/Value3d.js" as Value3d

// A post-processing effect written as render passes. A scene environment
// runs the effects declared inside it in order, each pass reading the
// previous one's output.
Effect {
    id: effect3d

    required property var renderer

    passes: renderer.childObjectsAndReferences(["pass_3d"], "passes")

    // Uniforms the effect's shaders can read. QML needs a declared
    // property per uniform, so Zui offers one documented set.
    property real time: Number(renderer.prop("time", 0))
    property real intensity: Number(renderer.prop("intensity", 1))
    property real amount: Number(renderer.prop("amount", 1))
    property real radius: Number(renderer.prop("radius", 1))
    property real progress: Number(renderer.prop("progress", 0))
    property color tint: renderer.prop("tint", "white")
    property vector4d parameters: Value3d.vector4d(renderer.prop("parameters", null), 0, 0, 0, 0)
    property TextureInput texture0: renderer.sceneObject(renderer.prop("texture0", ""))
    property TextureInput texture1: renderer.sceneObject(renderer.prop("texture1", ""))
}
