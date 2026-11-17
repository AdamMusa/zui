import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A terrain mesh built from the brightness of a height map image, scaled
// to the extents given.
HeightFieldGeometry {
    id: heightFieldGeometry

    required property var renderer

    Support.Prop3dBinding {
        renderer: heightFieldGeometry.renderer
        target: heightFieldGeometry
        name: "source"
        property: "source"
        value: heightFieldGeometry.renderer.assetUrl(heightFieldGeometry.renderer.prop("source"))
    }

    Support.Prop3dBinding {
        renderer: heightFieldGeometry.renderer
        target: heightFieldGeometry
        name: "smooth_shading"
        property: "smoothShading"
        value: heightFieldGeometry.renderer.prop("smooth_shading") === true
    }

    Support.Prop3dBinding {
        renderer: heightFieldGeometry.renderer
        target: heightFieldGeometry
        name: "extents"
        property: "extents"
        value: Value3d.vector3d(heightFieldGeometry.renderer.prop("extents"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: heightFieldGeometry.renderer
        target: heightFieldGeometry
        name: "height_map"
        property: "heightMap"
        value: heightFieldGeometry.renderer.assetUrl(heightFieldGeometry.renderer.prop("height_map"))
    }
}
