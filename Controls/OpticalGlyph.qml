import QtQuick
import "../Theme"

Item {
  property alias text: glyph.text
  property alias color: glyph.color
  property alias fontFamily: glyph.font.family
  property alias fontSize: glyph.font.pixelSize
  property bool debugBounds: false
  implicitWidth: glyph.implicitWidth
  implicitHeight: glyph.implicitHeight
  Rectangle { anchors.fill: parent; visible: parent.debugBounds; color: "transparent"; border.color: Color.accent }
  Text { id: glyph; anchors.centerIn: parent; color: Color.foreground; font.family: Fonts.iconFamily; font.pixelSize: Style.font.icon }
}
