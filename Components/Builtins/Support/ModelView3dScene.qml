import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils

Item {
    id: modelViewRoot

    required property var renderer
    property real currentPitch: Number(renderer.prop("rotation_x", 0))
    property real currentYaw: Number(renderer.prop("rotation_y", 0))
    property real currentRoll: Number(renderer.prop("rotation_z", 0))
    property real currentZoom: clampZoom(Number(renderer.prop("zoom", 1)))
    property real automaticYaw: 0
    property real fittedScale: 1
    property real boundsDiameter: 0
    property vector3d modelCenter: Qt.vector3d(0, 0, 0)
    property real observedResetRevision: Number(renderer.prop("reset_revision", 0))
    property bool ready: false
    property string loadedModelSource: ""

    function clampZoom(value) {
        return Math.max(Number(renderer.prop("minimum_zoom", 0.65)), Math.min(Number(renderer.prop("maximum_zoom", 3.2)), Number(value)));
    }

    function event(name, payload) {
        if (renderer.subscribed(name))
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {
        });

    }

    function sendRotation() {
        event("rotation_change", {
            "x": currentPitch,
            "y": currentYaw,
            "z": currentRoll
        });
    }

    function setZoom(value, notify) {
        currentZoom = clampZoom(value);
        if (notify)
            event("zoom_change", {
            "value": currentZoom
        });

    }

    function resetView(notify) {
        currentPitch = Number(renderer.prop("rotation_x", 0));
        currentYaw = Number(renderer.prop("rotation_y", 0));
        currentRoll = Number(renderer.prop("rotation_z", 0));
        setZoom(Number(renderer.prop("zoom", 1)), notify);
        if (notify)
            sendRotation();

    }

    function updateBounds() {
        var bounds = runtimeModel.bounds;
        var size = Qt.vector3d(bounds.maximum.x - bounds.minimum.x, bounds.maximum.y - bounds.minimum.y, bounds.maximum.z - bounds.minimum.z);
        var diameter = Math.max(size.x, size.y, size.z);
        boundsDiameter = diameter;
        if (!isFinite(diameter) || diameter <= 0) {
            fittedScale = Number(renderer.prop("model_scale", 1));
            modelCenter = Qt.vector3d(Number(renderer.prop("center_x", 0)), Number(renderer.prop("center_y", 0)), Number(renderer.prop("center_z", 0)));
            return ;
        }
        modelCenter = Qt.vector3d((bounds.maximum.x + bounds.minimum.x) / 2, (bounds.maximum.y + bounds.minimum.y) / 2, (bounds.maximum.z + bounds.minimum.z) / 2);
        var requestedScale = Number(renderer.prop("model_scale", 0));
        fittedScale = requestedScale > 0 ? requestedScale : Number(renderer.prop("fit_size", 230)) / diameter;
    }

    function syncFromRenderer() {
        var revision = Number(renderer.prop("reset_revision", 0));
        if (revision !== observedResetRevision) {
            observedResetRevision = revision;
            resetView(false);
            return ;
        }
        if (!orbitDrag.active) {
            currentPitch = Number(renderer.prop("rotation_x", currentPitch));
            currentYaw = Number(renderer.prop("rotation_y", currentYaw));
            currentRoll = Number(renderer.prop("rotation_z", currentRoll));
        }
        if (!zoomPinch.active)
            setZoom(Number(renderer.prop("zoom", currentZoom)), false);

    }

    function synchronizeModelSource() {
        var requestedSource = String(renderer.assetUrl(renderer.prop("source", "")));
        if (requestedSource === loadedModelSource)
            return ;

        ready = false;
        loadedModelSource = requestedSource;
        runtimeModel.source = requestedSource;
    }

    implicitWidth: Number(renderer.prop("width", 420))
    implicitHeight: Number(renderer.prop("height", 420))
    clip: true
    Component.onCompleted: {
        synchronizeModelSource();
        syncFromRenderer();
    }

    Rectangle {
        anchors.fill: parent
        color: renderer.prop("background", "transparent")
    }

    View3D {
        id: scene

        anchors.fill: parent

        PerspectiveCamera {
            id: camera

            z: Number(renderer.prop("camera_distance", 460))
            fieldOfView: Number(renderer.prop("field_of_view", 36))
            clipNear: 0.5
            clipFar: 5000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-28, -34, 0)
            color: renderer.prop("key_light_color", "#ffffff")
            brightness: Number(renderer.prop("light_brightness", 1.35))
            castsShadow: true
            shadowFactor: 70
            shadowMapQuality: Light.ShadowMapQualityHigh
        }

        PointLight {
            position: Qt.vector3d(-180, 90, 240)
            color: renderer.prop("fill_light_color", "#ffffff")
            brightness: Number(renderer.prop("light_brightness", 1.35)) * 5
            quadraticFade: 2e-05
            linearFade: 0.003
        }

        Node {
            id: orbitNode

            eulerRotation: Qt.vector3d(modelViewRoot.currentPitch, modelViewRoot.currentYaw + modelViewRoot.automaticYaw, modelViewRoot.currentRoll)
            scale: Qt.vector3d(modelViewRoot.fittedScale * modelViewRoot.currentZoom, modelViewRoot.fittedScale * modelViewRoot.currentZoom, modelViewRoot.fittedScale * modelViewRoot.currentZoom)

            RuntimeLoader {
                id: runtimeModel

                source: ""
                position: Qt.vector3d(-modelViewRoot.modelCenter.x, -modelViewRoot.modelCenter.y, -modelViewRoot.modelCenter.z)
                onBoundsChanged: modelViewRoot.updateBounds()
                onStatusChanged: {
                    modelViewRoot.event("status", {
                        "value": status,
                        "error": errorString
                    });
                    if (status === RuntimeLoader.Success) {
                        modelViewRoot.ready = true;
                        modelViewRoot.updateBounds();
                        modelViewRoot.event("loaded", {
                            "source": source,
                            "width": bounds.maximum.x - bounds.minimum.x,
                            "height": bounds.maximum.y - bounds.minimum.y,
                            "depth": bounds.maximum.z - bounds.minimum.z
                        });
                    } else if (status === RuntimeLoader.Error) {
                        modelViewRoot.ready = false;
                        renderer.componentError("model_load_failed", errorString, {
                            "source": source,
                            "status": status
                        });
                    }
                }
            }

        }

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Transparent
            antialiasingMode: String(renderer.prop("antialiasing", "msaa")) === "none" ? SceneEnvironment.NoAA : SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.VeryHigh
            temporalAAEnabled: false
            aoStrength: 45
            aoDistance: 12
            tonemapMode: SceneEnvironment.TonemapModeAces
        }

    }

    DragHandler {
        id: orbitDrag

        property real startingPitch: 0
        property real startingYaw: 0

        enabled: renderer.prop("interactive", true) !== false
        target: null
        acceptedButtons: Qt.LeftButton
        onActiveChanged: {
            if (active) {
                startingPitch = modelViewRoot.currentPitch;
                startingYaw = modelViewRoot.currentYaw;
            } else {
                modelViewRoot.sendRotation();
            }
        }
        onTranslationChanged: {
            if (!active)
                return ;

            modelViewRoot.currentYaw = startingYaw + translation.x * 0.48;
            modelViewRoot.currentPitch = Math.max(-88, Math.min(88, startingPitch - translation.y * 0.42));
        }
    }

    PinchHandler {
        id: zoomPinch

        property real startingZoom: 1

        enabled: renderer.prop("interactive", true) !== false
        target: null
        minimumScale: Number(renderer.prop("minimum_zoom", 0.65))
        maximumScale: Number(renderer.prop("maximum_zoom", 3.2))
        onActiveChanged: {
            if (active)
                startingZoom = modelViewRoot.currentZoom;
            else
                modelViewRoot.event("zoom_change", {
                "value": modelViewRoot.currentZoom
            });
        }
        onActiveScaleChanged: {
            if (active)
                modelViewRoot.setZoom(startingZoom * activeScale, false);

        }
    }

    WheelHandler {
        id: zoomWheel

        enabled: renderer.prop("interactive", true) !== false
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            modelViewRoot.setZoom(modelViewRoot.currentZoom * Math.exp(event.angleDelta.y / 900), true);
            event.accepted = true;
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold
        onTapped: function(eventPoint) {
            modelViewRoot.event("click", {
                "x": eventPoint.position.x,
                "y": eventPoint.position.y
            });
        }
        onDoubleTapped: function(eventPoint) {
            modelViewRoot.setZoom(modelViewRoot.currentZoom + 0.55, true);
            modelViewRoot.event("double_click", {
                "x": eventPoint.position.x,
                "y": eventPoint.position.y,
                "zoom": modelViewRoot.currentZoom
            });
        }
    }

    Connections {
        function onNodeChanged() {
            modelViewRoot.synchronizeModelSource();
            modelViewRoot.syncFromRenderer();
        }

        target: renderer
    }

    NumberAnimation on automaticYaw {
        from: 0
        to: 360
        duration: Math.max(1000, Math.round(360000 / Math.max(0.1, Number(renderer.prop("auto_rotate_speed", 4)))))
        loops: Animation.Infinite
        running: renderer.prop("auto_rotate", false) === true && !orbitDrag.active
    }

}
