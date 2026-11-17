import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Displaces the image along a noise texture, so the scene looks painted.
BrushStrokes {
    id: brushStrokes

    required property var renderer

    Support.Prop3dBinding {
        renderer: brushStrokes.renderer
        target: brushStrokes
        name: "noise_sample"
        property: "noiseSample"
        value: brushStrokes.renderer.sceneObject(brushStrokes.renderer.prop("noise_sample"))
    }

    Support.Prop3dBinding {
        renderer: brushStrokes.renderer
        target: brushStrokes
        name: "brush_length"
        property: "brushLength"
        value: Number(brushStrokes.renderer.prop("brush_length"))
    }

    Support.Prop3dBinding {
        renderer: brushStrokes.renderer
        target: brushStrokes
        name: "brush_size"
        property: "brushSize"
        value: Number(brushStrokes.renderer.prop("brush_size"))
    }

    Support.Prop3dBinding {
        renderer: brushStrokes.renderer
        target: brushStrokes
        name: "brush_angle"
        property: "brushAngle"
        value: Number(brushStrokes.renderer.prop("brush_angle"))
    }
}
