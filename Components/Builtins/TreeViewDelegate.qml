import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.ItemDelegate {
    id: delegateRoot

    property var renderer: null
    readonly property bool expanded: renderer && renderer.prop("expanded", false) === true

    text: (renderer && renderer.prop("has_children", false) === true ? (expanded ? "▾ " : "▸ ") : "") + (renderer ? String(renderer.prop("text", "")) : "")
    enabled: !renderer || renderer.prop("enabled", true) !== false
    leftPadding: Number(renderer ? renderer.prop("depth", 0) * renderer.prop("indentation", 18) : 0) + 8
    implicitWidth: Number(renderer ? renderer.prop("width", 220) : 220)
    implicitHeight: Number(renderer ? renderer.prop("height", 42) : 42)
    highlighted: renderer && (renderer.prop("selected", false) === true || renderer.prop("current", false) === true)
    onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, renderer.prop("has_children", false) === true ? (expanded ? "collapse" : "expand") : "click", {
        "row": renderer.prop("row", -1),
        "column": renderer.prop("column", -1),
        "value": renderer.prop("value", null)
    })
    onDoubleClicked: {
        var payload = {
            "row": renderer.prop("row", -1),
            "column": renderer.prop("column", -1),
            "value": renderer.prop("value", null)
        };
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "double_click", payload);
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload);
    }

    background: Rectangle {
        color: delegateRoot.highlighted ? renderer.prop("selected_background", Color.popups.background) : renderer.prop("background", "transparent")
        border.color: renderer.prop("border_color", "transparent")
    }

    contentItem: Text {
        text: delegateRoot.text
        color: delegateRoot.highlighted ? renderer.prop("selected_foreground", renderer.foreground) : renderer.prop("foreground", renderer.foreground)
        font.family: renderer.prop("font_family", renderer.fontFamily)
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

}
