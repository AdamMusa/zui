import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.ItemDelegate {
    id: headerDelegate

    property var renderer: null

    text: renderer ? String(renderer.prop("text", "")) : ""
    enabled: !renderer || renderer.prop("enabled", true) !== false
    implicitWidth: Number(renderer ? renderer.prop("width", 160) : 160)
    implicitHeight: Number(renderer ? renderer.prop("height", 42) : 42)
    highlighted: renderer && renderer.prop("selected", false) === true
    onClicked: {
        var payload = {
            "index": renderer.prop("index", -1),
            "value": renderer.prop("value", null)
        };
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", payload);
        payload.order = String(renderer.prop("sort_order", "")) === "ascending" ? "descending" : "ascending";
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "sort", payload);
    }

    background: Rectangle {
        color: headerDelegate.highlighted ? renderer.prop("selected_background", Color.popups.background) : renderer.prop("background", Color.background)
        border.color: renderer.prop("border_color", Color.muted)
    }

    contentItem: Text {
        text: headerDelegate.text + (renderer.prop("sort_order", "") === "ascending" ? " ▲" : (renderer.prop("sort_order", "") === "descending" ? " ▼" : ""))
        color: headerDelegate.highlighted ? renderer.prop("selected_foreground", renderer.foreground) : renderer.prop("foreground", renderer.foreground)
        font.family: renderer.prop("font_family", renderer.fontFamily)
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

}
