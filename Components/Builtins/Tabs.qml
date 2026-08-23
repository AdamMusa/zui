import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"

QQC.Control {
  id: tabsRoot

  required property var renderer
  readonly property int pageCount: renderer.node && Array.isArray(renderer.node.children)
    ? renderer.node.children.length : 0
  readonly property int requestedIndex: Number(renderer.prop("current_index", 0))
  readonly property bool barAtBottom: String(renderer.prop("position", "top")) === "bottom"
  property int currentIndex: 0
  property bool synchronizing: false

  function boundedIndex(value) {
    return pageCount === 0 ? -1 : Math.max(0, Math.min(pageCount - 1, Number(value)))
  }

  function labelAt(index) {
    var labels = renderer.prop("labels", [])
    if (Array.isArray(labels) && index < labels.length) {
      var label = labels[index]
      return label !== null && typeof label === "object" && label.label !== undefined
        ? String(label.label) : String(label)
    }
    var child = renderer.node.children[index]
    return child && child.props && child.props.title !== undefined
      ? String(child.props.title) : "Tab " + String(index + 1)
  }

  function syncSelection() {
    var next = boundedIndex(requestedIndex)
    if (currentIndex === next) return
    synchronizing = true
    currentIndex = next
    synchronizing = false
  }

  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 420))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  LayoutMirroring.enabled: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
  LayoutMirroring.childrenInherit: true

  background: Rectangle {
    color: renderer.prop("content_background", renderer.prop("background", Color.background))
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Item {
    QQC.TabBar {
      id: nativeBar
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: tabsRoot.barAtBottom ? undefined : parent.top
      anchors.bottom: tabsRoot.barAtBottom ? parent.bottom : undefined
      implicitWidth: 0
      height: Number(renderer.prop("tab_height", 44))
      currentIndex: tabsRoot.currentIndex

      background: Rectangle {
        color: renderer.prop("background", Color.background)
      }

      Repeater {
        model: tabsRoot.pageCount
        QQC.TabButton {
          required property int index
          width: Number(renderer.prop("tab_width", 0)) > 0
            ? Number(renderer.prop("tab_width", 0))
            : Math.max(1, nativeBar.width / Math.max(1, tabsRoot.pageCount))
          height: nativeBar.height
          text: tabsRoot.labelAt(index)
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
          contentItem: Text {
            text: parent.text
            color: parent.checked ? renderer.prop("accent", Color.accent)
              : renderer.prop("foreground", renderer.foreground)
            font: parent.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
          background: Rectangle {
            property bool selected: parent.checked
            color: "transparent"
            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: parent.selected ? 2 : 0
              color: renderer.prop("accent", Color.accent)
            }
          }
          onClicked: {
            tabsRoot.currentIndex = index
            if (renderer.subscribed("tab_click"))
              renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                "tab_click", { value: index, label: text })
          }
        }
      }
    }

    StackLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: tabsRoot.barAtBottom ? parent.top : nativeBar.bottom
      anchors.bottom: tabsRoot.barAtBottom ? nativeBar.top : parent.bottom
      currentIndex: tabsRoot.currentIndex
      Repeater {
        model: renderer.node.children || []
        delegate: renderer.layoutChildDelegateComponent
      }
    }
  }

  onRequestedIndexChanged: syncSelection()
  onPageCountChanged: syncSelection()
  Component.onCompleted: syncSelection()
  onCurrentIndexChanged: {
    if (synchronizing || currentIndex < 0) return
    if (renderer.subscribed("input"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: currentIndex })
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: currentIndex })
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
