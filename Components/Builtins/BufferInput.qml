import QtQuick
import QtQuick3D
import "Support" as Support

// Binds a buffer to a named sampler of the pass that declares it, which
// is how one pass reads what another wrote.
BufferInput {
    id: bufferInput

    required property var renderer

    buffer: renderer.childObjectOrReference(["buffer_3d"], "buffer")

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: bufferInput.renderer
            target: bufferInput
            name: "sampler"
            property: "sampler"
            value: String(bufferInput.renderer.prop("sampler"))
        }
    ]
}
