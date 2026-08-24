import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.CheckBox {
    id: checkControl

    required property var renderer

    text: renderer.escapeAutoText(renderer.prop("label", ""))
    checked: renderer.prop("checked", false) === true
    hoverEnabled: true
    spacing: Number(renderer.prop("spacing", Style.spacing.controlGap))
    leftPadding: 0
    rightPadding: 0
    onToggled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
        "value": checked
    })
    onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", {
        "value": hovered
    })

    HoverHandler {
        cursorShape: renderer.cursorShape(renderer.prop("cursor", "pointing_hand"))
    }

    indicator: Rectangle {
        implicitWidth: Number(renderer.prop("indicator_size", Style.space(20)))
        implicitHeight: implicitWidth
        x: checkControl.leftPadding
        y: checkControl.topPadding + (checkControl.availableHeight - height) / 2
        radius: Math.min(Style.cornerRadius, width / 4)
        color: checkControl.checked ? renderer.prop("accent", Color.accent) : renderer.prop("background", "transparent")
        border.width: Style.normalBorderWidth
        border.color: checkControl.checked ? renderer.prop("accent", Color.accent) : renderer.prop("foreground", renderer.foreground)

        Text {
            anchors.centerIn: parent
            text: checkControl.checked ? renderer.iconGlyph("check") : ""
            textFormat: Text.PlainText
            color: Color.background
            font.family: renderer.iconFontFamily
            font.pixelSize: parent.width * 0.7
        }

    }

    contentItem: Text {
        leftPadding: checkControl.indicator.width + checkControl.spacing
        text: checkControl.text
        textFormat: Text.PlainText
        color: renderer.prop("foreground", renderer.foreground)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        verticalAlignment: Text.AlignVCenter
    }

}
