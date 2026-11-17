import QtQuick
import QtQuick3D
import "Support" as Support

// Sets one named uniform of the pass that declares it, so a value can be
// driven from Ruby without a declared QML property.
SetUniformValue {
    id: setUniformValue

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: setUniformValue.renderer
            target: setUniformValue
            name: "target"
            property: "target"
            value: String(setUniformValue.renderer.prop("target"))
        },
        Support.Prop3dBinding {
            renderer: setUniformValue.renderer
            target: setUniformValue
            name: "value"
            property: "value"
            value: setUniformValue.renderer.prop("value")
        }
    ]
}
