import QtQuick
import "../Theme"

Column {
  id: root
  property string title: ""
  property string meta: ""
  property string detail: ""
  property real iconSize: Style.font.display
  property real iconOpacity: 1
  property real metaOpacity: 1
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  spacing: Style.spacing.xs
  Text { text: root.title; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.heading; font.bold: true }
  Text { text: root.meta; color: root.foreground; opacity: root.metaOpacity; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
  Text { text: root.detail; color: root.foreground; opacity: 0.72; font.family: root.fontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
}
