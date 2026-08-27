pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Window

Item {
  id: viewport
  required property var renderer

  readonly property var hostWindow: Window.window
  width: hostWindow ? hostWindow.width : (parent ? parent.width : 390)
  height: hostWindow ? hostWindow.height : (parent ? parent.height : 844)
  clip: true

  readonly property real safeLeft: zuiMobile ? Number(zuiSafeArea.left) : 0
  readonly property real safeTop: zuiMobile ? Number(zuiSafeArea.top) : 0
  readonly property real safeRight: zuiMobile ? Number(zuiSafeArea.right) : 0
  readonly property real safeBottom: zuiMobile ? Number(zuiSafeArea.bottom) : 0
  readonly property real outerPadding: Number(renderer.prop("padding", zuiMobile ? 12 : 18))
  readonly property real cardWidth: Math.max(240, Number(renderer.prop("card_width", 348)))
  readonly property real cardSpacing: Math.max(0, Number(renderer.prop("spacing", 12)))
  readonly property int maximumColumns: Math.max(1, Number(renderer.prop("max_columns", 4)))
  readonly property real availableWidth: Math.max(1, width - safeLeft - safeRight - outerPadding * 2)
  readonly property int columns: Math.max(1, Math.min(maximumColumns,
    Math.floor((availableWidth + cardSpacing) / (cardWidth + cardSpacing))))
  readonly property real cellWidth: (availableWidth - cardSpacing * (columns - 1)) / columns
  readonly property int requestedIndex: Math.max(0, Number(renderer.prop("scroll_index", 0)))

  function revealRequestedCard() {
    var wrapper = cards.itemAt(Math.min(requestedIndex, Math.max(0, cards.count - 1)))
    if (!wrapper) return
    feed.contentY = Math.max(0, Math.min(wrapper.y - outerPadding,
      Math.max(0, feed.contentHeight - feed.height)))
  }

  Rectangle {
    anchors.fill: parent
    color: viewport.renderer.prop("background", "transparent")
  }

  Flickable {
    id: feed
    x: viewport.safeLeft
    y: viewport.safeTop
    width: Math.max(1, viewport.width - viewport.safeLeft - viewport.safeRight)
    height: Math.max(1, viewport.height - viewport.safeTop - viewport.safeBottom)
    contentWidth: width
    contentHeight: cardFlow.height + viewport.outerPadding * 2
    boundsBehavior: Flickable.DragAndOvershootBounds
    flickableDirection: Flickable.VerticalFlick
    interactive: true
    clip: true

    onContentYChanged: if (moving && viewport.renderer.subscribed("scroll"))
      viewport.renderer.bridge.sendEvent(viewport.renderer.surfaceName, viewport.renderer.controlId,
        "scroll", { x: contentX, y: contentY })

    Flow {
      id: cardFlow
      x: viewport.outerPadding
      y: viewport.outerPadding
      width: viewport.availableWidth
      spacing: viewport.cardSpacing

      Repeater {
        id: cards
        model: viewport.renderer.node && Array.isArray(viewport.renderer.node.children)
          ? viewport.renderer.node.children : []
        delegate: Item {
          id: cardWrapper
          required property var modelData
          width: viewport.cellWidth
          readonly property real contentScale: Math.min(1, width / viewport.cardWidth)
          height: Math.ceil(cardLoader.implicitHeight * contentScale)

          Loader {
            id: cardLoader
            x: Math.max(0, (parent.width - width * scale) / 2)
            y: 0
            width: viewport.cardWidth
            scale: cardWrapper.contentScale
            transformOrigin: Item.TopLeft
            source: Qt.resolvedUrl("../../ControlNode.qml")
            onLoaded: {
              item.renderDepth = viewport.renderer.renderDepth + 1
              item.bridge = viewport.renderer.bridge
              item.surfaceName = viewport.renderer.surfaceName
              item.controlId = String(cardWrapper.modelData.id)
              item.foreground = viewport.renderer.foreground
              item.fontFamily = viewport.renderer.fontFamily
            }
          }
        }
      }
    }

    QQC.ScrollIndicator.vertical: QQC.ScrollIndicator {}
  }

  onRequestedIndexChanged: Qt.callLater(revealRequestedCard)
  onColumnsChanged: Qt.callLater(revealRequestedCard)
  Component.onCompleted: Qt.callLater(revealRequestedCard)
}
