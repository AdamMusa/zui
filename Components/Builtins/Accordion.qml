import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Control {
  id: accordionRoot

  required property var renderer
  readonly property int sectionCount: renderer.node && Array.isArray(renderer.node.children)
    ? renderer.node.children.length : 0
  readonly property string requestedSignature: JSON.stringify(renderer.prop("expanded_indices", []))
  property var expandedIndices: []
  property bool synchronizing: false

  function titleAt(index) {
    var titles = renderer.prop("titles", [])
    if (Array.isArray(titles) && index < titles.length) return String(titles[index])
    var child = renderer.node.children[index]
    return child && child.props && child.props.title !== undefined
      ? String(child.props.title) : "Section " + String(index + 1)
  }

  function subtitleAt(index) {
    var subtitles = renderer.prop("subtitles", [])
    return Array.isArray(subtitles) && index < subtitles.length ? String(subtitles[index]) : ""
  }

  function normalizedIndices(values) {
    var source = Array.isArray(values) ? values : (values === null || values === undefined ? [] : [values])
    var result = []
    for (var index = 0; index < source.length; index++) {
      var value = Math.floor(Number(source[index]))
      if (value >= 0 && value < sectionCount && result.indexOf(value) < 0) result.push(value)
    }
    result.sort(function(left, right) { return left - right })
    if (renderer.prop("multiple", false) !== true && result.length > 1) result = [result[0]]
    return result
  }

  function syncExpanded() {
    synchronizing = true
    expandedIndices = normalizedIndices(renderer.prop("expanded_indices", []))
    synchronizing = false
  }

  function isExpanded(index) {
    return expandedIndices.indexOf(index) >= 0
  }

  function activate(index) {
    if (!enabled) return
    var opening = !isExpanded(index)
    var next = expandedIndices.slice(0)
    if (opening) {
      if (renderer.prop("multiple", false) === true) next.push(index)
      else next = [index]
    } else {
      next.splice(next.indexOf(index), 1)
    }
    next.sort(function(left, right) { return left - right })
    expandedIndices = next
    var payload = { index: index, expanded: opening, values: next }
    if (renderer.subscribed("toggle"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "toggle", payload)
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
    var direction = opening ? "expand" : "collapse"
    if (renderer.subscribed(direction))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, direction, payload)
  }

  implicitWidth: Number(renderer.prop("width", 600))
  implicitHeight: renderer.prop("height", null) === null
    ? sections.implicitHeight : Number(renderer.prop("height", sections.implicitHeight))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false

  background: Rectangle {
    color: renderer.prop("background", "transparent")
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Column {
    id: sections
    spacing: Number(renderer.prop("spacing", Style.spacing.sm))

    Repeater {
      model: accordionRoot.sectionCount
      Item {
        id: sectionRoot
        required property int index
        readonly property bool expanded: accordionRoot.isExpanded(index)
        readonly property real headerHeight: Number(renderer.prop("header_height", 60))
        width: sections.width
        height: headerHeight + (expanded
          ? bodyLoader.implicitHeight + Number(renderer.prop("padding", Style.spacing.lg)) * 2 : 0)
        clip: true

        Behavior on height {
          enabled: renderer.prop("animated", true) !== false
          NumberAnimation {
            duration: Number(renderer.prop("duration", 200))
            easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad"))
          }
        }

        Rectangle {
          anchors.fill: parent
          color: sectionRoot.expanded
            ? renderer.prop("expanded_background", renderer.prop("background", Color.background))
            : renderer.prop("background", Color.background)
          radius: Number(renderer.prop("radius", Style.cornerRadius))
          border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
          border.color: renderer.prop("border_color", "transparent")
        }

        QQC.ToolButton {
          id: sectionHeader
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: sectionRoot.headerHeight
          enabled: accordionRoot.enabled
          onClicked: accordionRoot.activate(sectionRoot.index)

          contentItem: Item {
            Text {
              id: sectionTitle
              anchors.left: parent.left
              anchors.right: sectionIndicator.left
              anchors.top: accordionRoot.subtitleAt(sectionRoot.index).length > 0 ? parent.top : undefined
              anchors.verticalCenter: accordionRoot.subtitleAt(sectionRoot.index).length === 0
                ? parent.verticalCenter : undefined
              text: accordionRoot.titleAt(sectionRoot.index)
              color: renderer.prop("foreground", renderer.foreground)
              font.family: String(renderer.prop("font_family", renderer.fontFamily))
              font.pixelSize: Number(renderer.prop("title_size",
                renderer.prop("font_size", Style.font.body)))
              font.bold: true
              elide: Text.ElideRight
            }
            Text {
              anchors.left: parent.left
              anchors.right: sectionIndicator.left
              anchors.top: sectionTitle.bottom
              text: accordionRoot.subtitleAt(sectionRoot.index)
              visible: text.length > 0
              color: renderer.prop("muted", Color.muted)
              font.family: String(renderer.prop("font_family", renderer.fontFamily))
              font.pixelSize: Number(renderer.prop("subtitle_size", Style.font.caption))
              elide: Text.ElideRight
            }
            Text {
              id: sectionIndicator
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: renderer.iconGlyph("chevron_down")
              color: renderer.prop("accent", Color.accent)
              font.family: renderer.iconFontFamily
              font.pixelSize: Number(renderer.prop("indicator_size", Style.font.icon))
              rotation: sectionRoot.expanded ? 180 : 0
              Behavior on rotation {
                enabled: renderer.prop("animated", true) !== false
                NumberAnimation { duration: Number(renderer.prop("duration", 200)) }
              }
            }
          }
          background: Rectangle {
            color: renderer.prop("header_background", "transparent")
            radius: Number(renderer.prop("radius", Style.cornerRadius))
          }
        }

        Loader {
          id: bodyLoader
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: sectionHeader.bottom
          anchors.margins: Number(renderer.prop("padding", Style.spacing.lg))
          visible: sectionRoot.expanded
          opacity: sectionRoot.expanded ? 1 : 0
          source: Qt.resolvedUrl("../../ControlNode.qml")
          onLoaded: {
            item.bridge = renderer.bridge
            item.surfaceName = renderer.surfaceName
            item.controlId = String(renderer.node.children[sectionRoot.index].id)
            item.foreground = renderer.foreground
            item.fontFamily = renderer.fontFamily
          }
          Behavior on opacity {
            enabled: renderer.prop("animated", true) !== false
            NumberAnimation { duration: Number(renderer.prop("duration", 120)) }
          }
        }
      }
    }
  }

  onRequestedSignatureChanged: syncExpanded()
  onSectionCountChanged: syncExpanded()
  Component.onCompleted: syncExpanded()
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
