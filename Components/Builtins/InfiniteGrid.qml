import QtQuick
import QtQuick3D.Helpers
import "Support" as Support

// A ground grid that keeps going to the horizon, drawn by the viewport
// rather than by geometry, so it costs nothing to extend.
InfiniteGrid {
    id: infiniteGrid

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: infiniteGrid.renderer
            target: infiniteGrid
            name: "visible"
            property: "visible"
            value: infiniteGrid.renderer.prop("visible") === true
        },
        Support.Prop3dBinding {
            renderer: infiniteGrid.renderer
            target: infiniteGrid
            name: "grid_interval"
            property: "gridInterval"
            value: Number(infiniteGrid.renderer.prop("grid_interval"))
        },
        Support.Prop3dBinding {
            renderer: infiniteGrid.renderer
            target: infiniteGrid
            name: "grid_axes"
            property: "gridAxes"
            value: infiniteGrid.renderer.prop("grid_axes") === true
        }
    ]
}
