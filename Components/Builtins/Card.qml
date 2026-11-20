import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.BorderSurface {
  id: surface
  required property var renderer
      readonly property int pad: Number(renderer.prop("padding", Style.space(16)))
      // A card sized by its content centres that content, which is the same
      // thing as padding it. A card given an explicit height — one tile of a
      // grid of equal cards — used to centre it too, which drags the heading
      // away from the top edge and opens a band of dead space above and below.
      // `alignment` holds the content at the padding origin instead.
      readonly property string contentAlignment: String(renderer.prop("alignment", "center"))
      readonly property bool centred: contentAlignment !== "start" && contentAlignment !== "top"
        && contentAlignment !== "end" && contentAlignment !== "bottom"
      implicitWidth: cardContent.implicitWidth + pad * 2
      implicitHeight: cardContent.implicitHeight + pad * 2
      color: renderer.prop("color", Color.popups.background)
      radius: Number(renderer.prop("radius", Style.cornerRadius))
      borderSpec: Border.controlSpec("normal", renderer.prop("border_color", renderer.foreground), renderer.prop("accent", Color.accent))
      Column {
        id: cardContent
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
        spacing: Number(renderer.prop("spacing", Style.spacing.panelGap))
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
