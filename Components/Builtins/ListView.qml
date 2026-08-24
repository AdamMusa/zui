import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ListView {
  required property var renderer
      id: listControl
      readonly property var sourceItems: renderer.prop("items", [])
      readonly property string keyField: String(renderer.prop("key_field", "id"))
      readonly property string labelField: String(renderer.prop("label_field", "label"))
      readonly property string descriptionField: String(renderer.prop("description_field", "description"))
      readonly property string iconField: String(renderer.prop("icon_field", "icon"))
      implicitWidth: Number(renderer.prop("width", 280)); implicitHeight: Number(renderer.prop("height", 240))
      orientation: String(renderer.prop("orientation", "vertical")) === "horizontal" ? ListView.Horizontal : ListView.Vertical
      spacing: Number(renderer.prop("spacing", Style.spacing.labelGap)); clip: true; model: sourceItems
      currentIndex: {
        var selected = renderer.prop("selected", null)
        for (var i = 0; i < sourceItems.length; i++) {
          var item = sourceItems[i]
          var key = typeof item === "object" ? item[keyField] : item
          if (key === selected) return i
        }
        return -1
      }
      onContentXChanged: if (moving) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "scroll", { x: contentX, y: contentY })
      onContentYChanged: if (moving) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "scroll", { x: contentX, y: contentY })

      delegate: ZuiControls.CursorSurface {
        required property var modelData
        required property int index
        readonly property var value: typeof modelData === "object" ? modelData[listControl.keyField] : modelData
        width: listControl.orientation === ListView.Vertical ? listControl.width : implicitWidth
        implicitWidth: rowContent.implicitWidth + Style.spacing.rowPaddingX * 2
        implicitHeight: Math.max(Style.spacing.controlHeight, rowContent.implicitHeight + Style.spacing.controlPaddingY * 2)
        current: index === listControl.currentIndex
        foreground: renderer.foreground
        Row {
          id: rowContent
          anchors.centerIn: parent
          spacing: Style.spacing.controlGap
          Text { visible: text !== ""; text: renderer.iconGlyph(typeof modelData === "object" ? modelData[listControl.iconField] : ""); textFormat: Text.PlainText; color: renderer.foreground; font.family: renderer.iconFontFamilyFor(typeof modelData === "object" ? modelData[listControl.iconField] : "") }
          Column {
            Text { text: String(typeof modelData === "object" ? (modelData[listControl.labelField] ?? value) : modelData); textFormat: Text.PlainText; color: renderer.foreground; font.family: renderer.fontFamily }
            Text { visible: text !== ""; text: String(typeof modelData === "object" ? (modelData[listControl.descriptionField] || "") : ""); textFormat: Text.PlainText; color: Qt.darker(renderer.foreground, 1.4); font.family: renderer.fontFamily; font.pixelSize: Style.font.caption }
          }
        }
        MouseArea {
          anchors.fill: parent
          onClicked: {
            listControl.currentIndex = index
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: parent.value, index: index, item: modelData })
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", { value: parent.value, index: index, item: modelData })
          }
        }
      }

      Text {
        anchors.centerIn: parent; visible: listControl.count === 0
        text: String(renderer.prop("empty_text", "No items")); textFormat: Text.PlainText; color: Qt.darker(renderer.foreground, 1.4); font.family: renderer.fontFamily
      }
    }
