import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.HorizontalHeaderView {
  id: headerRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", 640) : 640)
  implicitHeight: Number(renderer ? renderer.prop("height", 42) : 42)
  model: renderer ? renderer.prop("sections", []) : []
  interactive: renderer && renderer.prop("movable", false) === true
  columnSpacing: Number(renderer ? renderer.prop("spacing", 1) : 1)
  delegate: Rectangle {
    required property int index
    required property var modelData
    implicitWidth: Number(renderer.prop("section_width", 160)); implicitHeight: headerRoot.height
    readonly property bool selected: index === Number(renderer.prop("current_index", -1))
    color: selected ? renderer.prop("selected_background", Color.popups.background) : renderer.prop("background", Color.background)
    border.color: renderer.prop("border_color", Color.muted)
    Text { anchors.fill: parent; anchors.margins: 8; text: String(modelData && modelData.label !== undefined ? modelData.label : modelData); color: parent.selected ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground)) : renderer.prop("foreground", renderer.foreground); font.family: renderer.prop("font_family", renderer.fontFamily); font.pixelSize: Number(renderer.prop("font_size", Style.font.body)); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
    TapHandler { enabled: renderer.prop("clickable", true) !== false; onTapped: { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { index: index, value: modelData }); var current = Number(renderer.prop("sort_index", -1)); var order = current === index && String(renderer.prop("sort_order", "ascending")) === "ascending" ? "descending" : "ascending"; renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "sort", { index: index, order: order, value: modelData }) } }
  }
}
