import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.Button {
    required property var renderer

    text: renderer.escapeAutoText(renderer.prop("text", ""))
    iconText: renderer.iconGlyph(renderer.prop("icon", ""))
    tooltipText: renderer.escapeAutoText(renderer.prop("tooltip", ""))
    selected: renderer.prop("selected", false) === true
    active: renderer.prop("active", false) === true
    hasCursor: renderer.prop("cursor", false) === true
    focusable: renderer.prop("focusable", true) !== false
    bordered: renderer.prop("bordered", true) !== false
    foreground: renderer.prop("foreground", renderer.foreground)
    background: renderer.prop("background", "transparent")
    accent: renderer.prop("accent", Color.accent)
    fontFamily: String(renderer.prop("font_family", renderer.fontFamily))
    iconFontFamily: renderer.iconFontFamilyFor(renderer.prop("icon", ""))
    fontSize: Number(renderer.prop("font_size", Style.font.body))
    iconSize: Number(renderer.prop("icon_size", Style.font.icon))
    iconRotation: Number(renderer.prop("icon_rotation", 0))
    iconSpinning: renderer.prop("icon_spinning", false) === true
    horizontalPadding: Number(renderer.prop("horizontal_padding", Style.spacing.controlPaddingX))
    verticalPadding: Number(renderer.prop("vertical_padding", Style.spacing.controlPaddingY))
    leftAlign: renderer.prop("left_align", false) === true
    tooltipBackground: renderer.prop("tooltip_background", Color.tooltip.background)
    tooltipForeground: renderer.prop("tooltip_foreground", Color.tooltip.text)
    tooltipBorder: renderer.prop("tooltip_border", Color.tooltip.border)
    onClicked: {
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {
        });
        const url = String(renderer.prop("url", ""));
        if (url.length > 0) {
            const opened = Qt.openUrlExternally(url);
            const eventName = opened ? "open" : "error";
            if (renderer.subscribed(eventName))
                renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, {
                "url": url
            });

        }
    }
    onRightClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "right_click", {
    })
    onHovered: function(value) {
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", {
            "value": value
        });
    }
}
