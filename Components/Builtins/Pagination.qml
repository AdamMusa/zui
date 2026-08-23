import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Pane {
  id: paginationRoot

  required property var renderer
  readonly property int pageCount: Math.max(0, Number(renderer.prop("count", 0)))
  readonly property int requestedPage: Number(renderer.prop("page", 1))
  readonly property var pageWindow: visiblePages()
  property int currentPage: 0
  property bool synchronizing: false

  function boundedPage(value) {
    return pageCount === 0 ? 0 : Math.max(1, Math.min(pageCount, Number(value)))
  }

  function syncSelection() {
    var next = boundedPage(requestedPage)
    if (currentPage === next) return
    synchronizing = true
    currentPage = next
    synchronizing = false
  }

  function visiblePages() {
    var result = []
    if (pageCount === 0) return result
    var siblings = Math.max(0, Number(renderer.prop("sibling_count", 1)))
    var threshold = siblings * 2 + 5
    if (pageCount <= threshold) {
      for (var all = 1; all <= pageCount; all++) result.push(all)
      return result
    }
    var start = Math.max(2, currentPage - siblings)
    var finish = Math.min(pageCount - 1, currentPage + siblings)
    if (currentPage <= siblings + 3) finish = Math.min(pageCount - 1, threshold - 2)
    if (currentPage >= pageCount - siblings - 2) start = Math.max(2, pageCount - threshold + 3)
    result.push(1)
    if (start > 2) result.push(0)
    for (var page = start; page <= finish; page++) result.push(page)
    if (finish < pageCount - 1) result.push(0)
    result.push(pageCount)
    return result
  }

  function choose(page, eventName) {
    var next = boundedPage(page)
    if (next === 0) return
    currentPage = next
    var payload = { value: next, page: next, count: pageCount }
    if (eventName && renderer.subscribed(eventName))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, payload)
    if (renderer.subscribed("select"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "select", payload)
  }

  implicitWidth: Number(renderer.prop("width", 620))
  implicitHeight: Number(renderer.prop("height", 52))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.xs))

  background: Rectangle {
    color: renderer.prop("background", "transparent")
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Row {
    spacing: Number(renderer.prop("spacing", Style.spacing.xs))

    QQC.ToolButton {
      visible: renderer.prop("show_first_last", false) === true
      enabled: paginationRoot.enabled && paginationRoot.currentPage > 1
      width: Number(renderer.prop("item_size", 40)); height: width
      text: String(renderer.prop("first_text", "«"))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      onClicked: paginationRoot.choose(1, "first")
    }

    QQC.ToolButton {
      visible: renderer.prop("show_previous_next", true) !== false
      enabled: paginationRoot.enabled && paginationRoot.currentPage > 1
      width: Number(renderer.prop("item_size", 40)); height: width
      text: String(renderer.prop("previous_text", "‹"))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      onClicked: paginationRoot.choose(paginationRoot.currentPage - 1, "previous")
    }

    Repeater {
      model: paginationRoot.pageWindow
      QQC.ToolButton {
        required property int modelData
        readonly property bool selected: modelData === paginationRoot.currentPage
        enabled: paginationRoot.enabled && modelData > 0
        width: Number(renderer.prop("item_size", 40)); height: width
        text: modelData === 0 ? "…" : String(modelData)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        contentItem: Text {
          text: parent.text
          color: !parent.enabled ? renderer.prop("muted", Color.muted)
            : (parent.selected ? renderer.prop("accent", Color.accent)
              : renderer.prop("foreground", renderer.foreground))
          font: parent.font
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
          color: parent.selected ? renderer.prop("selected_background", "transparent") : "transparent"
          radius: Number(renderer.prop("radius", Style.cornerRadius))
        }
        onClicked: paginationRoot.choose(modelData, null)
      }
    }

    QQC.ToolButton {
      visible: renderer.prop("show_previous_next", true) !== false
      enabled: paginationRoot.enabled && paginationRoot.currentPage < paginationRoot.pageCount
      width: Number(renderer.prop("item_size", 40)); height: width
      text: String(renderer.prop("next_text", "›"))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      onClicked: paginationRoot.choose(paginationRoot.currentPage + 1, "next")
    }

    QQC.ToolButton {
      visible: renderer.prop("show_first_last", false) === true
      enabled: paginationRoot.enabled && paginationRoot.currentPage < paginationRoot.pageCount
      width: Number(renderer.prop("item_size", 40)); height: width
      text: String(renderer.prop("last_text", "»"))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      onClicked: paginationRoot.choose(paginationRoot.pageCount, "last")
    }
  }

  onRequestedPageChanged: syncSelection()
  onPageCountChanged: syncSelection()
  Component.onCompleted: syncSelection()
  onCurrentPageChanged: {
    if (synchronizing || currentPage <= 0) return
    var payload = { value: currentPage, page: currentPage, count: pageCount }
    if (renderer.subscribed("input"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload)
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
