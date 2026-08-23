import QtQuick
import "../../Theme"

Rectangle {
    id: legendRoot

    property var renderer: null
    readonly property var items: renderer ? renderer.prop("items", []) : []
    readonly property bool horizontal: !renderer || String(renderer.prop("orientation", "horizontal")) === "horizontal"

    implicitWidth: Number(renderer ? renderer.prop("width", horizontal ? legendFlow.implicitWidth : 180) : 180)
    implicitHeight: Number(renderer ? renderer.prop("height", horizontal ? 36 : legendFlow.implicitHeight) : 36)
    color: renderer ? renderer.prop("background", "transparent") : "transparent"

    Flow {
        id: legendFlow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: implicitHeight
        spacing: Number(renderer ? renderer.prop("spacing", 12) : 12)
        flow: legendRoot.horizontal ? Flow.LeftToRight : Flow.TopToBottom

        Repeater {
            model: legendRoot.items

            delegate: Row {
                required property int index
                required property var modelData
                readonly property bool selected: {
                    var value = renderer.prop("selected", null);
                    return value === index || value === (modelData && modelData.value !== undefined ? modelData.value : modelData);
                }

                spacing: 6
                height: Math.max(marker.height, label.implicitHeight)
                opacity: renderer.prop("selected", null) === null || selected ? 1 : 0.55

                Rectangle {
                    id: marker

                    anchors.verticalCenter: parent.verticalCenter
                    width: Number(renderer.prop("marker_size", 12))
                    height: width
                    radius: width / 4
                    color: String(modelData && modelData.color !== undefined ? modelData.color : Color.accent)
                }

                Text {
                    id: label

                    anchors.verticalCenter: parent.verticalCenter
                    text: String(modelData && modelData.label !== undefined ? modelData.label : modelData)
                    color: parent.selected ? renderer.prop("foreground", renderer.foreground) : renderer.prop("muted", renderer.prop("foreground", renderer.foreground))
                    font.family: renderer.prop("font_family", renderer.fontFamily)
                    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
                }

                TapHandler {
                    enabled: renderer.prop("interactive", false) === true
                    onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "select", {
                        "index": index,
                        "item": modelData
                    })
                }

                HoverHandler {
                    enabled: renderer.subscribed("hover")
                    onHoveredChanged: {
                        if (hovered) {
                            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", {
                            "index": index,
                            "item": modelData
                        });
                        }
                    }
                }

            }

        }

    }

}
