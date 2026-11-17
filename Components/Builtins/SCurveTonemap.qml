import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Tonemaps through an S-shaped curve, with separate control over the
// shoulder and the toe.
SCurveTonemap {
    id: sCurveTonemap

    required property var renderer

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "shoulder_slope"
        property: "shoulderSlope"
        value: Number(sCurveTonemap.renderer.prop("shoulder_slope"))
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "shoulder_emphasis"
        property: "shoulderEmphasis"
        value: Number(sCurveTonemap.renderer.prop("shoulder_emphasis"))
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "toe_slope"
        property: "toeSlope"
        value: Number(sCurveTonemap.renderer.prop("toe_slope"))
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "toe_emphasis"
        property: "toeEmphasis"
        value: Number(sCurveTonemap.renderer.prop("toe_emphasis"))
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "contrast_boost"
        property: "contrastBoost"
        value: Number(sCurveTonemap.renderer.prop("contrast_boost"))
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "saturation_level"
        property: "saturationLevel"
        value: Number(sCurveTonemap.renderer.prop("saturation_level"))
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "gamma_value"
        property: "gammaValue"
        value: Number(sCurveTonemap.renderer.prop("gamma_value"))
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "use_exposure"
        property: "useExposure"
        value: sCurveTonemap.renderer.prop("use_exposure") === true
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "white_point"
        property: "whitePoint"
        value: Number(sCurveTonemap.renderer.prop("white_point"))
    }

    Support.Prop3dBinding {
        renderer: sCurveTonemap.renderer
        target: sCurveTonemap
        name: "exposure_value"
        property: "exposureValue"
        value: Number(sCurveTonemap.renderer.prop("exposure_value"))
    }
}
