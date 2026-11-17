import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Draws the three axes and a grid on each plane, so a scene under
// construction has a visible frame of reference.
AxisHelper {
    id: axisHelper

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: axisHelper
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: axisHelper.renderer
        target: axisHelper
        name: "grid_color"
        property: "gridColor"
        value: axisHelper.renderer.prop("grid_color")
    }

    Support.Prop3dBinding {
        renderer: axisHelper.renderer
        target: axisHelper
        name: "grid_opacity"
        property: "gridOpacity"
        value: Number(axisHelper.renderer.prop("grid_opacity"))
    }

    Support.Prop3dBinding {
        renderer: axisHelper.renderer
        target: axisHelper
        name: "xz_grid"
        property: "enableXZGrid"
        value: axisHelper.renderer.prop("xz_grid") === true
    }

    Support.Prop3dBinding {
        renderer: axisHelper.renderer
        target: axisHelper
        name: "xy_grid"
        property: "enableXYGrid"
        value: axisHelper.renderer.prop("xy_grid") === true
    }

    Support.Prop3dBinding {
        renderer: axisHelper.renderer
        target: axisHelper
        name: "yz_grid"
        property: "enableYZGrid"
        value: axisHelper.renderer.prop("yz_grid") === true
    }

    Support.Prop3dBinding {
        renderer: axisHelper.renderer
        target: axisHelper
        name: "axis_lines"
        property: "enableAxisLines"
        value: axisHelper.renderer.prop("axis_lines") === true
    }
}
