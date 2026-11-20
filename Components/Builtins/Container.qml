import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.BorderSurface {
  id: surface
  required property var renderer
      readonly property int innerPadding: Number(renderer.prop("padding", 0))
      // See Card.qml: `alignment` decides where the content sits when the
      // surface is larger than the content, instead of always centring it.
      readonly property string contentAlignment: String(renderer.prop("alignment", "center"))
      readonly property bool centred: contentAlignment !== "start" && contentAlignment !== "top"
        && contentAlignment !== "end" && contentAlignment !== "bottom"
      implicitWidth: content.implicitWidth + innerPadding * 2
      implicitHeight: content.implicitHeight + innerPadding * 2
      color: "transparent"
      borderSpec: renderer.prop("bordered", false)
        ? Border.controlSpec("normal", renderer.foreground, Color.accent)
        : Border.none()
      radius: Style.cornerRadius

      Column {
        id: content
        anchors.horizontalCenter: surface.centred ? surface.horizontalCenter : undefined
        anchors.left: surface.centred ? undefined : surface.left
        anchors.leftMargin: surface.innerPadding
        anchors.verticalCenter: surface.centred ? surface.verticalCenter : undefined
        anchors.top: surface.contentAlignment === "start" || surface.contentAlignment === "top"
          ? surface.top : undefined
        anchors.topMargin: surface.innerPadding
        anchors.bottom: surface.contentAlignment === "end" || surface.contentAlignment === "bottom"
          ? surface.bottom : undefined
        anchors.bottomMargin: surface.innerPadding
        spacing: Number(renderer.prop("spacing", Style.spacing.panelGap))

        Repeater {
          model: renderer.node && Array.isArray(renderer.node.children) ? renderer.node.children : []
          delegate: renderer.childDelegateComponent
        }
      }
    }
