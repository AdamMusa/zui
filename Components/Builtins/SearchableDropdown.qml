import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.SearchableDropdown {
  required property var renderer
      label: renderer.escapeAutoText(renderer.prop("label", "")); value: String(renderer.prop("value", "")); options: renderer.prop("options", [])
      placeholderText: String(renderer.prop("placeholder", "Search...")); emptyText: String(renderer.prop("empty_text", "No matches"))
      triggerLabel: String(renderer.prop("trigger_label", "")); width: Number(renderer.prop("width", 240))
      foreground: renderer.prop("foreground", renderer.foreground); background: renderer.prop("background", Color.popups.background)
      popupBorder: renderer.prop("popup_border", Color.popups.border); accent: renderer.prop("accent", Color.accent)
      fontFamily: String(renderer.prop("font_family", renderer.fontFamily)); rowHeight: Number(renderer.prop("row_height", Style.spacing.controlHeight))
      popupRowHeight: Number(renderer.prop("popup_row_height", Style.spacing.popupRowHeight)); popupMinHeight: Number(renderer.prop("popup_min_height", Style.spacing.searchablePopupMinHeight))
      showLabel: renderer.prop("show_label", true) !== false; hasCursor: renderer.prop("cursor", false) === true
      onChanged: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value }) }
      onOptionHovered: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: value }) }
    }
