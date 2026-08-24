import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.Toggle {
  required property var renderer
      label: renderer.escapeAutoText(renderer.prop("label", "")); description: renderer.escapeAutoText(renderer.prop("description", ""))
      checked: renderer.prop("checked", false) === true; hasCursor: renderer.prop("cursor", false) === true
      rounded: renderer.prop("rounded", Style.cornerRadius > 0) === true
      foreground: renderer.prop("foreground", renderer.foreground); accent: renderer.prop("accent", Color.accent)
      fontFamily: String(renderer.prop("font_family", renderer.fontFamily)); titleSize: Number(renderer.prop("title_size", Style.font.subtitle))
      descriptionSize: Number(renderer.prop("description_size", Style.font.caption))
      onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: !checked })
      onHovered: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: value }) }
    }
