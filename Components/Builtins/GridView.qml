import QtQuick
import "../../Theme"

Rectangle {
  id: gridRoot

  required property var renderer
  readonly property var sourceItems: renderer.prop("items", [])
  readonly property string keyField: String(renderer.prop("key_field", "id"))
  readonly property string labelField: String(renderer.prop("label_field", "label"))
  readonly property string descriptionField: String(renderer.prop("description_field", "description"))
  readonly property string iconField: String(renderer.prop("icon_field", "icon"))
  readonly property real gridSpacing: Number(renderer.prop("spacing", Style.spacing.md))
  readonly property real gridPadding: Number(renderer.prop("padding", Style.spacing.md))

  function itemValue(item) {
    return item !== null && typeof item === "object" ? item[keyField] : item
  }

  function itemLabel(item) {
    if (item !== null && typeof item === "object") {
      var label = item[labelField]
      return String(label === undefined || label === null ? itemValue(item) : label)
    }
    return String(item === undefined || item === null ? "" : item)
  }

  function itemDescription(item) {
    if (item !== null && typeof item === "object") return String(item[descriptionField] || "")
    return ""
  }

  function itemIcon(item) {
    if (item !== null && typeof item === "object") return String(item[iconField] || "")
    return ""
  }

  function selectedIndex() {
    var explicitIndex = renderer.prop("current_index", null)
    if (explicitIndex !== null) return Math.max(-1, Math.min(sourceItems.length - 1, Number(explicitIndex)))
    var selectedValue = renderer.prop("selected", null)
    if (selectedValue === null) return -1
    for (var index = 0; index < sourceItems.length; index++) {
      if (itemValue(sourceItems[index]) === selectedValue) return index
    }
    return -1
  }

  function snapModeValue(value) {
    var name = String(value || "none")
    if (name === "row" || name === "snap_to_row") return GridView.SnapToRow
    if (name === "one_row" || name === "snap_one_row") return GridView.SnapOneRow
    return GridView.NoSnap
  }

  function boundsBehaviorValue(value) {
    var name = String(value || "drag_overshoot")
    if (name === "stop") return Flickable.StopAtBounds
    if (name === "drag") return Flickable.DragOverBounds
    if (name === "overshoot") return Flickable.OvershootBounds
    return Flickable.DragAndOvershootBounds
  }

  function itemPayload(index) {
    if (index < 0 || index >= sourceItems.length) return { value: null, index: -1, item: null }
    var item = sourceItems[index]
    return { value: itemValue(item), index: index, item: item }
  }

  function activateIndex(index) {
    if (index < 0 || index >= sourceItems.length) return
    gridControl.currentIndex = index
    var payload = itemPayload(index)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload)
  }

  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 420))
  color: renderer.prop("background", "transparent")
  radius: Number(renderer.prop("radius", Style.cornerRadius))
  border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
  border.color: renderer.prop("border_color", "transparent")
  enabled: renderer.prop("enabled", true) !== false
  Accessible.name: String(renderer.prop("accessible_name", "Grid"))
  Accessible.role: Accessible.List

  GridView {
    id: gridControl
    anchors.fill: parent
    anchors.margins: gridRoot.gridPadding
    model: gridRoot.sourceItems
    cellWidth: Number(renderer.prop("cell_width", 160))
    cellHeight: Number(renderer.prop("cell_height", 120))
    flow: String(renderer.prop("flow", "left_to_right")) === "top_to_bottom"
      ? GridView.FlowTopToBottom : GridView.FlowLeftToRight
    layoutDirection: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
      ? Qt.RightToLeft : Qt.LeftToRight
    currentIndex: gridRoot.selectedIndex()
    highlightMoveDuration: Number(renderer.prop("highlight_move_duration", 180))
    snapMode: gridRoot.snapModeValue(renderer.prop("snap_mode", "none"))
    boundsBehavior: gridRoot.boundsBehaviorValue(renderer.prop("bounds_behavior", "drag_overshoot"))
    keyNavigationWraps: renderer.prop("key_navigation_wraps", false) === true
    interactive: renderer.prop("interactive", true) !== false
    clip: renderer.prop("clip", true) !== false
    focus: true

    delegate: Rectangle {
      required property var modelData
      required property int index
      readonly property bool current: index === gridControl.currentIndex

      width: Math.max(0, gridControl.cellWidth - gridRoot.gridSpacing)
      height: Math.max(0, gridControl.cellHeight - gridRoot.gridSpacing)
      radius: Number(renderer.prop("radius", Style.cornerRadius))
      color: current
        ? renderer.prop("selected_background", Color.popups.background)
        : renderer.prop("cell_background", "transparent")
      border.width: current ? Style.normalBorderWidth : 0
      border.color: renderer.prop("accent", Color.accent)

      Column {
        anchors.fill: parent
        anchors.margins: gridRoot.gridSpacing
        spacing: Style.spacing.sm

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: text.length > 0
          text: renderer.iconGlyph(gridRoot.itemIcon(modelData))
          color: current
            ? renderer.prop("selected_foreground", renderer.prop("accent", Color.accent))
            : renderer.prop("foreground", renderer.foreground)
          font.family: renderer.iconFontFamilyFor(gridRoot.itemIcon(modelData))
          font.pixelSize: Number(renderer.prop("icon_size", 28))
        }

        Text {
          width: parent.width
          text: gridRoot.itemLabel(modelData)
          color: current
            ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
            : renderer.prop("foreground", renderer.foreground)
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: text.length > 0
          text: gridRoot.itemDescription(modelData)
          color: renderer.prop("muted", Color.muted)
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("description_size", Style.font.caption))
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }
      }

      MouseArea {
        anchors.fill: parent
        enabled: gridRoot.enabled
        hoverEnabled: true
        onClicked: gridRoot.activateIndex(index)
      }
    }

    highlight: Rectangle {
      width: Math.max(0, gridControl.cellWidth - gridRoot.gridSpacing)
      height: Math.max(0, gridControl.cellHeight - gridRoot.gridSpacing)
      radius: Number(renderer.prop("radius", Style.cornerRadius))
      color: "transparent"
      border.width: Style.normalBorderWidth
      border.color: renderer.prop("accent", Color.accent)
    }

    Keys.onReturnPressed: function(event) {
      gridRoot.activateIndex(currentIndex)
      event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
      gridRoot.activateIndex(currentIndex)
      event.accepted = true
    }
    Keys.onSpacePressed: function(event) {
      gridRoot.activateIndex(currentIndex)
      event.accepted = true
    }

    onCurrentIndexChanged: {
      var payload = gridRoot.itemPayload(currentIndex)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "current_change", payload)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "highlight", payload)
    }
    onCountChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "count_change", { value: count })
    onContentXChanged: {
      if (moving) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "scroll", { x: contentX, y: contentY })
    }
    onContentYChanged: {
      if (moving) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "scroll", { x: contentX, y: contentY })
    }
    onMovementStarted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "movement_start", { x: contentX, y: contentY })
    onMovementEnded: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "movement_end", { x: contentX, y: contentY })
    onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      activeFocus ? "focus" : "blur", {})
  }

  Text {
    anchors.centerIn: parent
    visible: gridControl.count === 0
    text: String(renderer.prop("empty_text", "No items"))
    color: renderer.prop("muted", Color.muted)
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  }

  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
