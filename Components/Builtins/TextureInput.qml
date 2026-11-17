import QtQuick
import QtQuick3D

// Hands a texture to a custom material or post-processing effect as a
// named shader input, and can switch it off without rewriting the shader.
// A texture input is not part of the object tree: declare it anywhere in
// the scene and name it from one of the material's texture slots.
TextureInput {
    id: textureInput

    required property var renderer

    texture: renderer.sceneObject(renderer.prop("texture", ""))
    enabled: renderer.prop("enabled", true) !== false
}
