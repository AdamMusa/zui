import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

Rectangle {
  id: reorderRoot

  property var renderer: null
  readonly property var items: renderer ? renderer.prop("items", []) : []
  readonly property real outerPadding: Number(renderer ? renderer.prop("padding", 0) : 0)

  implicitWidth: Number(renderer ? renderer.prop("width", 360) : 360)
  implicitHeight: Number(renderer ? renderer.prop("height", 420) : 420)
  color: renderer ? renderer.prop("background", "transparent") : "transparent"
  radius: Number(renderer ? renderer.prop("radius", 0) : 0)
  border.color: renderer ? renderer.prop("border_color", "transparent") : "transparent"

  function field(item, name, fallback) {
    if (item !== null && typeof item === "object" && !Array.isArray(item)) {
      var key = String(renderer.prop(name, fallback))
      return item[key] === undefined ? null : item[key]
    }
    return item
  }

  function payload(index, item) {
    return { index: index, item: item, value: field(item, "key_field", "id") }
  }

  function send(name, payload) {
    if (renderer.subscribed(name))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  ListView {
    id: listControl

    anchors.fill: parent
    anchors.margins: reorderRoot.outerPadding
    model: reorderRoot.items
    orientation: String(renderer.prop("orientation", "vertical")) === "horizontal"
      ? ListView.Horizontal : ListView.Vertical
    spacing: Number(renderer.prop("spacing", 4))
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    displaced: Transition {
      NumberAnimation {
        properties: "x,y"
        duration: Number(renderer.prop("drag_transition_duration", 180))
        easing.type: Easing.OutCubic
      }
    }

    delegate: QQC.ItemDelegate {
      id: rowDelegate

      required property int index
      required property var modelData
      property real dragOffsetX: dragHandler.active ? dragHandler.translation.x : 0
      property real dragOffsetY: dragHandler.active ? dragHandler.translation.y : 0

      width: listControl.orientation === ListView.Vertical
        ? listControl.width : Number(renderer.prop("item_height", 58)) * 3.2
      height: listControl.orientation === ListView.Horizontal
        ? listControl.height : Number(renderer.prop("item_height", 58))
      highlighted: renderer.prop("selected", null) === reorderRoot.field(modelData, "key_field", "id")
      z: dragHandler.active ? 20 : 0
      scale: dragHandler.active ? Number(renderer.prop("drag_scale", 1.025)) : 1
      opacity: dragHandler.active ? Number(renderer.prop("drag_opacity", 0.94)) : 1
      leftPadding: Number(renderer.prop("item_padding", 12))
      rightPadding: Number(renderer.prop("item_padding", 12))
      topPadding: 7
      bottomPadding: 7
      transform: Translate { x: rowDelegate.dragOffsetX; y: rowDelegate.dragOffsetY }

      Behavior on dragOffsetX {
        NumberAnimation {
          duration: Number(renderer.prop("drag_transition_duration", 180))
          easing.type: Easing.OutCubic
        }
      }
      Behavior on dragOffsetY {
        NumberAnimation {
          duration: Number(renderer.prop("drag_transition_duration", 180))
          easing.type: Easing.OutCubic
        }
      }
      Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 130 } }

      background: Rectangle {
        color: rowDelegate.highlighted
          ? renderer.prop("selected_background", Color.popups.background)
          : renderer.prop("item_background", "transparent")
        radius: Number(renderer.prop("radius", 0))
        border.width: dragHandler.active ? 1 : 0
        border.color: renderer.prop("selected_foreground", renderer.foreground)
      }

      contentItem: Item {
        Text {
          id: handle
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: renderer.prop("drag_enabled", true) !== false
          text: "⋮⋮"
          color: dragHandler.active
            ? renderer.prop("selected_foreground", renderer.foreground)
            : renderer.prop("muted", Color.muted)
          font.pixelSize: Number(renderer.prop("font_size", Style.font.body)) + 2
          verticalAlignment: Text.AlignVCenter
        }

        Column {
          anchors.left: parent.left
          anchors.right: handle.left
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            text: String(reorderRoot.field(rowDelegate.modelData, "label_field", "label") || "")
            color: rowDelegate.highlighted
              ? renderer.prop("selected_foreground", renderer.foreground)
              : renderer.prop("foreground", renderer.foreground)
            font.family: renderer.prop("font_family", renderer.fontFamily)
            font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: String(reorderRoot.field(rowDelegate.modelData, "description_field", "description") || "")
            color: renderer.prop("muted", Color.muted)
            font.family: renderer.prop("font_family", renderer.fontFamily)
            font.pixelSize: Math.max(9, Number(renderer.prop("font_size", Style.font.body)) - 2)
            elide: Text.ElideRight
          }
        }
      }

      onClicked: {
        var eventPayload = reorderRoot.payload(index, modelData)
        reorderRoot.send("activate", eventPayload)
        reorderRoot.send("change", eventPayload)
      }

      DragHandler {
        id: dragHandler

        enabled: renderer.prop("drag_enabled", true) !== false
        target: null
        xAxis.enabled: listControl.orientation === ListView.Horizontal
        yAxis.enabled: listControl.orientation === ListView.Vertical

        onTranslationChanged: {
          if (!active) return
          var point = rowDelegate.mapToItem(listControl.contentItem,
                                            rowDelegate.width / 2 + translation.x,
                                            rowDelegate.height / 2 + translation.y)
          var targetIndex = listControl.indexAt(point.x, point.y)
          reorderRoot.send("drag_move", {
            from: rowDelegate.index,
            to: targetIndex,
            x: point.x,
            y: point.y,
            item: rowDelegate.modelData
          })
        }

        onActiveChanged: {
          if (active) {
            reorderRoot.send("drag_start", reorderRoot.payload(rowDelegate.index, rowDelegate.modelData))
            return
          }
          var point = rowDelegate.mapToItem(listControl.contentItem,
                                            rowDelegate.width / 2 + translation.x,
                                            rowDelegate.height / 2 + translation.y)
          var targetIndex = listControl.indexAt(point.x, point.y)
          if (targetIndex < 0) targetIndex = Math.max(0, reorderRoot.items.length - 1)
          reorderRoot.send("reorder", {
            from: rowDelegate.index,
            to: targetIndex,
            item: rowDelegate.modelData
          })
          reorderRoot.send("drag_end", {
            from: rowDelegate.index,
            to: targetIndex,
            item: rowDelegate.modelData
          })
        }
      }
    }

    Text {
      anchors.centerIn: parent
      visible: reorderRoot.items.length === 0
      text: renderer.prop("empty_text", "No items")
      color: renderer.prop("muted", Color.muted)
    }
  }
}
