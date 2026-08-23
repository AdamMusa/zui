import QtQuick
import "../Theme"

Rectangle {
  property var borderSpec: Border.none
  color: "transparent"
  radius: Style.cornerRadius
  border.color: borderSpec && borderSpec.color !== undefined ? borderSpec.color : "transparent"
  border.width: borderSpec && borderSpec.widths ? Number(borderSpec.widths.top || 0) : 0
}
