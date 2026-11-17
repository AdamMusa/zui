import QtQuick
import QtQuick3D
import "Support/Value3d.js" as Value3d

// A renderable mesh. The mesh comes from a built-in primitive or a .mesh asset
// through `source`, or from a geometry declared inside the model. Materials,
// morph targets, a skeleton and a skin can be declared inside the model too, or
// referenced by the Ruby id of a node declared elsewhere in the scene.
Model {
    id: model3d

    required property var renderer

    readonly property var materialTypes: ["principled_material", "default_material",
        "specular_glossy_material", "custom_material"]
    readonly property var geometryTypes: ["grid_geometry", "height_field_geometry",
        "procedural_mesh"]
    readonly property var instancingTypes: ["instance_list", "random_instancing", "file_instancing"]

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0),
                               renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null),
                                    renderer.prop("rotation_x", 0),
                                    renderer.prop("rotation_y", 0),
                                    renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))

    source: Value3d.meshSource(renderer, renderer.prop("source", ""))
    materials: renderer.childObjectsAndReferences(model3d.materialTypes, "materials")
    morphTargets: renderer.childObjectsAndReferences(["morph_target"], "morph_targets")
    geometry: renderer.childObjectOrReference(model3d.geometryTypes, "geometry")
    instancing: renderer.childObjectOrReference(model3d.instancingTypes, "instancing")
    instanceRoot: renderer.sceneObject(renderer.prop("instance_root", ""))
    skeleton: renderer.childObjectOrReference(["skeleton_3d"], "skeleton")
    skin: renderer.childObjectOrReference(["skin_3d"], "skin")
    bakedLightmap: renderer.childObjectOrReference(["baked_lightmap"], "baked_lightmap")
    inverseBindPoses: Value3d.matrixList(renderer.prop("inverse_bind_poses", []))
    pickable: renderer.prop("pickable", false) === true
    castsShadows: renderer.prop("casts_shadows", true) !== false
    receivesShadows: renderer.prop("receives_shadows", true) !== false
    castsReflections: renderer.prop("casts_reflections", true) !== false
    receivesReflections: renderer.prop("receives_reflections", true) !== false
    usedInBakedLighting: renderer.prop("used_in_baked_lighting", false) === true
    lightmapBaseResolution: Number(renderer.prop("lightmap_base_resolution", 1024))
    depthBias: Number(renderer.prop("depth_bias", 0))
    instancingLodMin: Number(renderer.prop("instancing_lod_min", -1))
    instancingLodMax: Number(renderer.prop("instancing_lod_max", -1))
    levelOfDetailBias: Number(renderer.prop("level_of_detail_bias", 1))

    onBoundsChanged: {
        renderer.emitEvent("bounds", {
            "minimum": [bounds.minimum.x, bounds.minimum.y, bounds.minimum.z],
            "maximum": [bounds.maximum.x, bounds.maximum.y, bounds.maximum.z]
        })
    }

    Binding {
        target: model3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }
}
