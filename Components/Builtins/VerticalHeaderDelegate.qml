import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.ItemDelegate {
    id: headerDelegate

    property var renderer: null

    text: renderer ? String(renderer.prop("text", "")) : ""
    enabled: !renderer || renderer.prop("enabled", true) !== false
    implicitWidth: Number(renderer ? renderer.prop("width", 80) : 80)
    implicitHeight: Number(renderer ? renderer.prop("height", 42) : 42)
    highlighted: renderer && renderer.prop("selected", false) === true
    font.family: renderer ? renderer.prop("font_family", renderer.fontFamily) : ""
    font.pixelSize: Number(renderer ? renderer.prop("font_size", Style.font.body) : Style.font.body)
    onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {
        "index": renderer.prop("index", -1),
        "value": renderer.prop("value", null)
    })

    background: Rectangle {
        color: headerDelegate.highlighted ? renderer.prop("selected_background", Color.popups.background) : renderer.prop("background", Color.background)
        border.color: renderer.prop("border_color", Color.muted)
    }

    contentItem: Text {
        text: headerDelegate.text
        color: headerDelegate.highlighted ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground)) : renderer.prop("foreground", renderer.foreground)
        font: headerDelegate.font
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

}
