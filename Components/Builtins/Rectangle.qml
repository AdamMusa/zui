import QtQuick
import QtQuick as Quick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Quick.Rectangle {
  id: surface
  required property var renderer
      readonly property int pad: Number(renderer.prop("padding", 0))
      // See Card.qml: `alignment` decides where the content sits when the
      // rectangle is larger than the content, instead of always centring it.
      readonly property string contentAlignment: String(renderer.prop("alignment", "center"))
      readonly property bool centred: contentAlignment !== "start" && contentAlignment !== "top"
        && contentAlignment !== "end" && contentAlignment !== "bottom"
      implicitWidth: Number(renderer.prop("width", contentColumn.implicitWidth + pad * 2))
      implicitHeight: Number(renderer.prop("height", contentColumn.implicitHeight + pad * 2))
      color: renderer.prop("color", "transparent")
      radius: Number(renderer.prop("radius", 0))
      border.color: renderer.prop("border_color", "transparent")
      border.width: Number(renderer.prop("border_width", 0))
      Column {
        id: contentColumn
        anchors.horizontalCenter: surface.centred ? surface.horizontalCenter : undefined
        anchors.left: surface.centred ? undefined : surface.left
        anchors.leftMargin: surface.pad
        anchors.verticalCenter: surface.centred ? surface.verticalCenter : undefined
        anchors.top: surface.contentAlignment === "start" || surface.contentAlignment === "top"
          ? surface.top : undefined
        anchors.topMargin: surface.pad
        anchors.bottom: surface.contentAlignment === "end" || surface.contentAlignment === "bottom"
          ? surface.bottom : undefined
        anchors.bottomMargin: surface.pad
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
