import QtQuick
import QtQuick.Controls as QQC
import "../Theme"

Column {
  id: root
  property string label: ""
  property var values: []
  property var options: []
  property string placeholderText: "Search..."
  property var optionsCommand: []
  property string optionsCommandCwd: ""
  property string emptyText: "No options"
  property string noSelectionText: "None selected"
  property string triggerLabel: ""
  property bool showLabel: true
  property color foreground: Color.foreground
  property color background: Color.popups.background
  property color popupBorder: Color.popups.border
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real rowHeight: Style.spacing.controlHeight
  property real popupRowHeight: Style.spacing.popupRowHeight
  property real popupMinHeight: Style.spacing.searchablePopupMinHeight
  property bool hasCursor: false
  signal changed(var values)
  signal optionHovered(var value)
  spacing: Style.spacing.xs
  Text { visible: root.showLabel && root.label !== ""; text: root.label; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
  QQC.Button { hoverEnabled: true; text: root.triggerLabel !== "" ? root.triggerLabel : (root.values.length > 0 ? root.values.join(", ") : root.noSelectionText); onClicked: menu.open(); onHoveredChanged: root.optionHovered(hovered); background: Rectangle { color: root.background; radius: Style.cornerRadius; border.color: root.popupBorder } }
  QQC.Menu { id: menu; Repeater { model: root.options; QQC.MenuItem { required property var modelData; text: String(modelData); checkable: true; checked: root.values.indexOf(String(modelData)) >= 0; onTriggered: { var next = root.values.slice(); var index = next.indexOf(String(modelData)); index >= 0 ? next.splice(index, 1) : next.push(String(modelData)); root.changed(next) } } } }
}
