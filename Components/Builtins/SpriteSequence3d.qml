import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Animates a sprite particle's image through the frames of a sprite
// sheet, forwards, backwards or alternating.
SpriteSequence3D {
    id: spriteSequence3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: spriteSequence3d.renderer
            target: spriteSequence3d
            name: "frame_count"
            property: "frameCount"
            value: Number(spriteSequence3d.renderer.prop("frame_count"))
        },
        Support.Prop3dBinding {
            renderer: spriteSequence3d.renderer
            target: spriteSequence3d
            name: "frame_index"
            property: "frameIndex"
            value: Number(spriteSequence3d.renderer.prop("frame_index"))
        },
        Support.Prop3dBinding {
            renderer: spriteSequence3d.renderer
            target: spriteSequence3d
            name: "interpolate"
            property: "interpolate"
            value: spriteSequence3d.renderer.prop("interpolate") === true
        },
        Support.Prop3dBinding {
            renderer: spriteSequence3d.renderer
            target: spriteSequence3d
            name: "duration"
            property: "duration"
            value: Number(spriteSequence3d.renderer.prop("duration"))
        },
        Support.Prop3dBinding {
            renderer: spriteSequence3d.renderer
            target: spriteSequence3d
            name: "duration_variation"
            property: "durationVariation"
            value: Number(spriteSequence3d.renderer.prop("duration_variation"))
        },
        Support.Prop3dBinding {
            renderer: spriteSequence3d.renderer
            target: spriteSequence3d
            name: "random_start"
            property: "randomStart"
            value: spriteSequence3d.renderer.prop("random_start") === true
        },
        Support.Prop3dBinding {
            renderer: spriteSequence3d.renderer
            target: spriteSequence3d
            name: "animation_direction"
            property: "animationDirection"
            value: Value3d.enumeration(spriteSequence3d.renderer.prop("animation_direction"), {
                "normal": SpriteSequence3D.Normal,
                "reverse": SpriteSequence3D.Reverse,
                "alternate": SpriteSequence3D.Alternate,
                "alternate_reverse": SpriteSequence3D.AlternateReverse,
                "single_frame": SpriteSequence3D.SingleFrame
            }, SpriteSequence3D.Normal)
        }
    ]
}
