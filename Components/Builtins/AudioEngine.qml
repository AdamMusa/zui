import QtQuick
import QtQuick3D.SpatialAudio
import "Support" as Support
import "Support/Value3d.js" as Value3d

// The spatial audio engine a scene's sounds are mixed through. Declare
// one per scene and pick how it renders: surround, stereo or
// headphones.
AudioEngine {
    id: audioEngine

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: audioEngine.renderer
            target: audioEngine
            name: "output_mode"
            property: "outputMode"
            value: Value3d.enumeration(audioEngine.renderer.prop("output_mode"), {
                "surround": AudioEngine.Surround,
                "stereo": AudioEngine.Stereo,
                "headphone": AudioEngine.Headphone
            }, AudioEngine.Surround)
        },
        Support.Prop3dBinding {
            renderer: audioEngine.renderer
            target: audioEngine
            name: "master_volume"
            property: "masterVolume"
            value: Number(audioEngine.renderer.prop("master_volume"))
        }
    ]
}
