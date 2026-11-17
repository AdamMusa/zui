import QtQuick
import QtQuick3D

// One render pass of an effect: the shaders it runs, the commands that
// set up its inputs, and the buffer it writes to. Leaving output unset
// writes to the screen.
Pass {
    id: pass3d

    required property var renderer

    shaders: renderer.childObjectsAndReferences(["shader_3d"], "shaders")
    commands: renderer.childObjectsAndReferences(["buffer_input", "set_uniform_value"], "commands")
    output: renderer.childObjectOrReference(["buffer_3d"], "output")
}
