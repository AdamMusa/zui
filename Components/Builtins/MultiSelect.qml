import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.MultiSelect {
  required property var renderer
      label: renderer.escapeAutoText(renderer.prop("label", "")); values: renderer.prop("values", []); options: renderer.prop("options", [])
      placeholderText: String(renderer.prop("placeholder", "Search...")); enabled: renderer.prop("enabled", true) !== false
      optionsCommand: renderer.prop("options_command", []); optionsCommandCwd: String(renderer.prop("options_command_cwd", ""))
      emptyText: String(renderer.prop("empty_text", "No options")); noSelectionText: String(renderer.prop("no_selection_text", "None selected"))
      triggerLabel: String(renderer.prop("trigger_label", "")); showLabel: renderer.prop("show_label", true) !== false
      width: Number(renderer.prop("width", 240)); foreground: renderer.prop("foreground", renderer.foreground)
      background: renderer.prop("background", Color.popups.background); popupBorder: renderer.prop("popup_border", Color.popups.border)
      accent: renderer.prop("accent", Color.accent); fontFamily: String(renderer.prop("font_family", renderer.fontFamily))
      rowHeight: Number(renderer.prop("row_height", Style.spacing.controlHeight)); popupRowHeight: Number(renderer.prop("popup_row_height", Style.spacing.popupRowHeight))
      popupMinHeight: Number(renderer.prop("popup_min_height", Style.spacing.searchablePopupMinHeight)); hasCursor: renderer.prop("cursor", false) === true
      onChanged: function(values) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: values }) }
      onOptionHovered: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: value }) }
    }
