import QtQuick
import "../Theme"

BorderSurface {
  id: root

  property bool hasCursor: false
  property bool current: false
  property bool outline: false
  property bool bordered: false
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color fill: Style.hoverFillFor(foreground, accent)
  property color currentFill: Style.selectedFillFor(foreground, accent)

  color: hasCursor ? fill : (current ? currentFill : "transparent")
  radius: Style.cornerRadius
  borderSpec: hasCursor
    ? Border.controlSpec("hover-cursor", foreground, accent)
    : (current
      ? Border.controlSpec("selected", foreground, accent)
      : (bordered
        ? Border.controlSpec("normal", foreground, accent)
        : Border.none()))

  Behavior on color {
    ColorAnimation { duration: 60 }
  }
}
