import QtQuick

// Applies one Qt Quick 3D property only while Ruby declares it.
//
// Qt gives most of its 3D rendering knobs a tuned default, and a Zui adapter
// should not have to restate those defaults to stay out of the way. Binding
// through this helper leaves the Qt default in place until an application sets
// the property, and puts it back when the application stops setting it.
Binding {
    required property var renderer
    required property string name

    when: renderer.hasProp(name)
    restoreMode: Binding.RestoreBindingOrValue
}
