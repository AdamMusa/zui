import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Animates a 3D node's orientation along the shortest arc between two
// rotations, which is what Euler angles cannot do: interpolating them
// separately swings a node through poses nobody asked for.
//
// The target is a node in the same scene, named by its Ruby id. The rotation
// can be given as a quaternion through `from` and `to`, or as Euler angles
// through from_x_rotation and the rest; whichever Ruby declares is the one
// applied, so the two never fight.
QuaternionAnimation {
    id: quaternionAnimation

    required property var renderer
    readonly property var targetNode: renderer.sceneObject(renderer.prop("target", ""))
    property bool requestedRunning: false

    function send(name, payload) {
        renderer.emitEvent(name, payload);
    }

    function loopsValue() {
        var value = renderer.prop("loops", 1);
        return String(value) === "infinite" || Number(value) < 0 ? Animation.Infinite : Math.max(1, Number(value));
    }

    function synchronize(restart) {
        requestedRunning = renderer.prop("running", false) === true;
        if (renderer.prop("paused", false) === true) {
            pause();
            return;
        }
        if (!requestedRunning) {
            delayTimer.stop();
            stop();
            return;
        }
        if (restart || !running) {
            stop();
            var delay = Math.max(0, Number(renderer.prop("delay", 0)));
            if (delay > 0) {
                delayTimer.interval = delay;
                delayTimer.restart();
            } else {
                start();
            }
        } else if (paused) {
            resume();
        }
    }

    target: quaternionAnimation.targetNode
    property: String(renderer.prop("property", "rotation"))
    duration: Number(renderer.prop("duration", 250))
    easing.type: Value3d.easingType(renderer.prop("easing", "in_out_quad"))
    loops: quaternionAnimation.loopsValue()
    alwaysRunToEnd: renderer.prop("always_run", false) === true
    type: Value3d.enumeration(renderer.prop("type", "slerp"), {
        "slerp": QuaternionAnimation.Slerp,
        "nlerp": QuaternionAnimation.Nlerp
    }, QuaternionAnimation.Slerp)

    onStarted: quaternionAnimation.send("start", {})
    onStopped: quaternionAnimation.send("stop", {})
    onFinished: quaternionAnimation.send("finish", {})
    onRunningChanged: quaternionAnimation.send("running_change", {
        "value": running
    })
    Component.onCompleted: quaternionAnimation.synchronize(false)

    // A QQuickPropertyAnimation has no default property, so the objects that
    // drive it live in a declared list rather than as children.
    property list<QtObject> drivers: [
        Timer {
            id: delayTimer

            repeat: false
            onTriggered: if (quaternionAnimation.requestedRunning)
                quaternionAnimation.start()
        },
        Connections {
            target: quaternionAnimation.renderer
            function onNodeChanged() {
                quaternionAnimation.synchronize(true);
            }
        },
        Support.Prop3dBinding {
            renderer: quaternionAnimation.renderer
            target: quaternionAnimation
            name: "from"
            property: "from"
            value: Value3d.quaternion(quaternionAnimation.renderer.prop("from"))
        },
        Support.Prop3dBinding {
            renderer: quaternionAnimation.renderer
            target: quaternionAnimation
            name: "to"
            property: "to"
            value: Value3d.quaternion(quaternionAnimation.renderer.prop("to"))
        },
        Support.Prop3dBinding {
            renderer: quaternionAnimation.renderer
            target: quaternionAnimation
            name: "from_x_rotation"
            property: "fromXRotation"
            value: Number(quaternionAnimation.renderer.prop("from_x_rotation"))
        },
        Support.Prop3dBinding {
            renderer: quaternionAnimation.renderer
            target: quaternionAnimation
            name: "from_y_rotation"
            property: "fromYRotation"
            value: Number(quaternionAnimation.renderer.prop("from_y_rotation"))
        },
        Support.Prop3dBinding {
            renderer: quaternionAnimation.renderer
            target: quaternionAnimation
            name: "from_z_rotation"
            property: "fromZRotation"
            value: Number(quaternionAnimation.renderer.prop("from_z_rotation"))
        },
        Support.Prop3dBinding {
            renderer: quaternionAnimation.renderer
            target: quaternionAnimation
            name: "to_x_rotation"
            property: "toXRotation"
            value: Number(quaternionAnimation.renderer.prop("to_x_rotation"))
        },
        Support.Prop3dBinding {
            renderer: quaternionAnimation.renderer
            target: quaternionAnimation
            name: "to_y_rotation"
            property: "toYRotation"
            value: Number(quaternionAnimation.renderer.prop("to_y_rotation"))
        },
        Support.Prop3dBinding {
            renderer: quaternionAnimation.renderer
            target: quaternionAnimation
            name: "to_z_rotation"
            property: "toZRotation"
            value: Number(quaternionAnimation.renderer.prop("to_z_rotation"))
        }
    ]
}
