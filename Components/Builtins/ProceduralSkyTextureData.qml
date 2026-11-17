import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A generated sky: horizon and zenith colours, ground colours, and a sun
// placed by latitude and longitude. A scene environment can use it as a
// light probe so the sky lights the scene it stands in.
ProceduralSkyTextureData {
    id: proceduralSkyTextureData

    required property var renderer

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sky_top_color"
        property: "skyTopColor"
        value: proceduralSkyTextureData.renderer.prop("sky_top_color")
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sky_horizon_color"
        property: "skyHorizonColor"
        value: proceduralSkyTextureData.renderer.prop("sky_horizon_color")
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sky_curve"
        property: "skyCurve"
        value: Number(proceduralSkyTextureData.renderer.prop("sky_curve"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sky_energy"
        property: "skyEnergy"
        value: Number(proceduralSkyTextureData.renderer.prop("sky_energy"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "ground_bottom_color"
        property: "groundBottomColor"
        value: proceduralSkyTextureData.renderer.prop("ground_bottom_color")
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "ground_horizon_color"
        property: "groundHorizonColor"
        value: proceduralSkyTextureData.renderer.prop("ground_horizon_color")
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "ground_curve"
        property: "groundCurve"
        value: Number(proceduralSkyTextureData.renderer.prop("ground_curve"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "ground_energy"
        property: "groundEnergy"
        value: Number(proceduralSkyTextureData.renderer.prop("ground_energy"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sun_color"
        property: "sunColor"
        value: proceduralSkyTextureData.renderer.prop("sun_color")
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sun_latitude"
        property: "sunLatitude"
        value: Number(proceduralSkyTextureData.renderer.prop("sun_latitude"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sun_longitude"
        property: "sunLongitude"
        value: Number(proceduralSkyTextureData.renderer.prop("sun_longitude"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sun_angle_min"
        property: "sunAngleMin"
        value: Number(proceduralSkyTextureData.renderer.prop("sun_angle_min"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sun_angle_max"
        property: "sunAngleMax"
        value: Number(proceduralSkyTextureData.renderer.prop("sun_angle_max"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sun_curve"
        property: "sunCurve"
        value: Number(proceduralSkyTextureData.renderer.prop("sun_curve"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "sun_energy"
        property: "sunEnergy"
        value: Number(proceduralSkyTextureData.renderer.prop("sun_energy"))
    }

    Support.Prop3dBinding {
        renderer: proceduralSkyTextureData.renderer
        target: proceduralSkyTextureData
        name: "texture_quality"
        property: "textureQuality"
        value: Value3d.enumeration(proceduralSkyTextureData.renderer.prop("texture_quality"), {
            "low": ProceduralSkyTextureData.SkyTextureQualityLow,
            "medium": ProceduralSkyTextureData.SkyTextureQualityMedium,
            "high": ProceduralSkyTextureData.SkyTextureQualityHigh,
            "very_high": ProceduralSkyTextureData.SkyTextureQualityVeryHigh
        }, ProceduralSkyTextureData.SkyTextureQualityLow)
    }
}
