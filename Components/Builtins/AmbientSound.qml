import QtQuick
import QtQuick3D.SpatialAudio
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A sound with no position, heard evenly wherever the listener stands,
// for a room tone or a score.
AmbientSound {
    id: ambientSound

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: ambientSound.renderer
            target: ambientSound
            name: "source"
            property: "source"
            value: ambientSound.renderer.assetUrl(ambientSound.renderer.prop("source"))
        },
        Support.Prop3dBinding {
            renderer: ambientSound.renderer
            target: ambientSound
            name: "volume"
            property: "volume"
            value: Number(ambientSound.renderer.prop("volume"))
        },
        Support.Prop3dBinding {
            renderer: ambientSound.renderer
            target: ambientSound
            name: "loops"
            property: "loops"
            value: Value3d.loops(ambientSound.renderer.prop("loops"), AmbientSound.Infinite)
        },
        Support.Prop3dBinding {
            renderer: ambientSound.renderer
            target: ambientSound
            name: "auto_play"
            property: "autoPlay"
            value: ambientSound.renderer.prop("auto_play") === true
        }
    ]
}
