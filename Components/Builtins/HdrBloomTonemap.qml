import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Blooms the bright parts of the scene and tonemaps the result, which is
// what makes lights look bright rather than merely pale.
HDRBloomTonemap {
    id: hdrBloomTonemap

    required property var renderer

    Support.Prop3dBinding {
        renderer: hdrBloomTonemap.renderer
        target: hdrBloomTonemap
        name: "gamma"
        property: "gamma"
        value: Number(hdrBloomTonemap.renderer.prop("gamma"))
    }

    Support.Prop3dBinding {
        renderer: hdrBloomTonemap.renderer
        target: hdrBloomTonemap
        name: "exposure"
        property: "exposure"
        value: Number(hdrBloomTonemap.renderer.prop("exposure"))
    }

    Support.Prop3dBinding {
        renderer: hdrBloomTonemap.renderer
        target: hdrBloomTonemap
        name: "bloom_threshold"
        property: "bloomThreshold"
        value: Number(hdrBloomTonemap.renderer.prop("bloom_threshold"))
    }

    Support.Prop3dBinding {
        renderer: hdrBloomTonemap.renderer
        target: hdrBloomTonemap
        name: "blur_falloff"
        property: "blurFalloff"
        value: Number(hdrBloomTonemap.renderer.prop("blur_falloff"))
    }

    Support.Prop3dBinding {
        renderer: hdrBloomTonemap.renderer
        target: hdrBloomTonemap
        name: "tonemapping_lerp"
        property: "tonemappingLerp"
        value: Number(hdrBloomTonemap.renderer.prop("tonemapping_lerp"))
    }

    Support.Prop3dBinding {
        renderer: hdrBloomTonemap.renderer
        target: hdrBloomTonemap
        name: "channel_threshold"
        property: "channelThreshold"
        value: Number(hdrBloomTonemap.renderer.prop("channel_threshold"))
    }
}
