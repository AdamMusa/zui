import QtQuick
import QtQuick3D
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Loads meshes, textures and geometries before anything needs them, so a
// scene does not stall the first time a model appears.
ResourceLoader {
    id: resourceLoader

    required property var renderer

    meshSources: Value3d.assetUrls(renderer, renderer.prop("mesh_sources", []))
    textures: renderer.childObjectsAndReferences(["texture_3d", "cube_map_texture"], "textures")
    geometries: renderer.childObjectsAndReferences(Scene3dTypes.geometries, "geometries")
}
