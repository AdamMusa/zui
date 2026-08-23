import QtQuick
import "../Theme"

Row {
  id: root
  property string value: ""
  property var options: []
  property color foreground: Color.foreground
  property color background: Color.background
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property bool focusable: true
  property int cursorIndex: -1
  signal changed(string value)
  signal hovered(int index, string value)
  spacing: 2
  Repeater { model: root.options; Button { required property var modelData; required property int index; text: String(modelData); selected: String(modelData) === root.value; foreground: root.foreground; background: root.background; accent: root.accent; fontFamily: root.fontFamily; fontSize: root.fontSize; onClicked: root.changed(String(modelData)); onHovered: function(value) { root.hovered(index, String(modelData)) } } }
}
