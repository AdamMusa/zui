import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// One shader stage of a render pass, loaded from a .vert or .frag asset.
Shader {
    id: shader3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: shader3d.renderer
            target: shader3d
            name: "shader"
            property: "shader"
            value: shader3d.renderer.assetUrl(shader3d.renderer.prop("shader"))
        },
        Support.Prop3dBinding {
            renderer: shader3d.renderer
            target: shader3d
            name: "stage"
            property: "stage"
            value: Value3d.enumeration(shader3d.renderer.prop("stage"), {
                "vertex": Shader.Vertex,
                "fragment": Shader.Fragment
            }, Shader.Vertex)
        }
    ]
}
