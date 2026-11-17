import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Skinning without a skeleton: a flat list of nodes to deform by, with
// the inverse bind pose of each. Lighter than a skeleton when the joints
// are already nodes in the scene.
Skin {
    id: skin3d

    required property var renderer

    joints: renderer.sceneObjects(renderer.prop("joints", []))

    Support.Prop3dBinding {
        renderer: skin3d.renderer
        target: skin3d
        name: "inverse_bind_poses"
        property: "inverseBindPoses"
        value: Value3d.matrixList(skin3d.renderer.prop("inverse_bind_poses"))
    }
}
