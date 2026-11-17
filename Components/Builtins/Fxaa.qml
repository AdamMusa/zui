import QtQuick
import QtQuick3D.Effects

// Fast approximate antialiasing as a post-processing pass, for when the
// scene environment's own antialiasing is too expensive.
Fxaa {
    id: fxaa

    required property var renderer
}
