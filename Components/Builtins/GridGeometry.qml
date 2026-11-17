import QtQuick
import QtQuick3D.Helpers
import "Support" as Support

// Line geometry for a grid of a declared size, to give a model_3d with a
// line-drawing material.
GridGeometry {
    id: gridGeometry

    required property var renderer

    Support.Prop3dBinding {
        renderer: gridGeometry.renderer
        target: gridGeometry
        name: "horizontal_lines"
        property: "horizontalLines"
        value: Number(gridGeometry.renderer.prop("horizontal_lines"))
    }

    Support.Prop3dBinding {
        renderer: gridGeometry.renderer
        target: gridGeometry
        name: "vertical_lines"
        property: "verticalLines"
        value: Number(gridGeometry.renderer.prop("vertical_lines"))
    }

    Support.Prop3dBinding {
        renderer: gridGeometry.renderer
        target: gridGeometry
        name: "horizontal_step"
        property: "horizontalStep"
        value: Number(gridGeometry.renderer.prop("horizontal_step"))
    }

    Support.Prop3dBinding {
        renderer: gridGeometry.renderer
        target: gridGeometry
        name: "vertical_step"
        property: "verticalStep"
        value: Number(gridGeometry.renderer.prop("vertical_step"))
    }
}
