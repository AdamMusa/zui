import QtQuick
import "../../Theme"

Rectangle {
  id: carouselRoot
  property var renderer: null
  readonly property var items: renderer ? renderer.prop("items", []) : []
  implicitWidth: Number(renderer ? renderer.prop("width", 640) : 640)
  implicitHeight: Number(renderer ? renderer.prop("height", 320) : 320)
  color: renderer ? renderer.prop("background", "transparent") : "transparent"

  function field(item, propertyName, fallback) {
    if (item !== null && typeof item === "object" && !Array.isArray(item)) {
      var key = String(renderer.prop(propertyName, fallback)); return item[key]
    }
    return item
  }
  PathView {
    id: pathControl
    anchors.fill: parent
    model: carouselRoot.items
    currentIndex: Number(renderer.prop("current_index", 0))
    interactive: renderer.prop("interactive", true) !== false
    preferredHighlightBegin: { var value=renderer.prop("highlight_range",0.5);return Array.isArray(value)?Number(value[0]):Number(value) }
    preferredHighlightEnd: { var value=renderer.prop("highlight_range",0.5);return Array.isArray(value)?Number(value[value.length-1]):Number(value) }
    highlightRangeMode: { var mode=String(renderer.prop("snap_mode","strict"));if(mode==="none")return PathView.NoHighlightRange;if(mode==="apply")return PathView.ApplyRange;return PathView.StrictlyEnforceRange }
    pathItemCount: Math.min(carouselRoot.items.length, 7)
    path: Path {
      startX: 0; startY: carouselRoot.height / 2
      PathCubic {
        x: carouselRoot.width
        y: carouselRoot.height / 2
        control1X: carouselRoot.width * 0.25
        control1Y: carouselRoot.height / 2 - Number(renderer.prop("path_radius", 72))
        control2X: carouselRoot.width * 0.75
        control2Y: carouselRoot.height / 2 - Number(renderer.prop("path_radius", 72))
      }
    }
    delegate: Rectangle {
      required property int index; required property var modelData
      width: Number(renderer.prop("item_width", 220)); height: Number(renderer.prop("item_height", 240))
      scale: PathView.isCurrentItem ? 1.0 : 0.72; opacity: PathView.isCurrentItem ? 1.0 : 0.45
      color: Color.popups.background; radius: Style.cornerRadius; border.color: index === pathControl.currentIndex ? renderer.prop("accent", Color.accent) : "transparent"
      Column {
        anchors.fill: parent; anchors.margins: 12; spacing: 8
        Image {
          width: parent.width
          height: parent.height - 76
          fillMode: Image.PreserveAspectCrop
          source: renderer.assetUrl(carouselRoot.field(modelData, "image_field", "image") || "")
          visible: source !== ""
          onStatusChanged: {
            if (status === Image.Error)
              renderer.componentError("carousel_image_failed",
                "Unable to load the declared carousel image",
                { index: index, source: String(source) })
          }
        }
        Text { width: parent.width; text: String(carouselRoot.field(modelData, "label_field", "label") || modelData); color: renderer.prop("foreground", renderer.foreground); font.family: renderer.prop("font_family", renderer.fontFamily); font.pixelSize: Number(renderer.prop("font_size", Style.font.body)); horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
        Text { width: parent.width; text: String(carouselRoot.field(modelData,"description_field","description")||"");color:renderer.prop("muted",renderer.foreground);font.family:renderer.prop("font_family",renderer.fontFamily);font.pixelSize:Math.max(9,Number(renderer.prop("font_size",Style.font.body))-2);horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight }
      }
      TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", { index: index, item: modelData, value: carouselRoot.field(modelData, "key_field", "id") }) }
    }
    onCurrentIndexChanged: {
      var payload = { value: currentIndex, item: currentIndex >= 0 && currentIndex < carouselRoot.items.length ? carouselRoot.items[currentIndex] : null }
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
    }
    onMovementStarted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "movement_start", {})
    onMovementEnded: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "movement_end", { value: currentIndex })
  }
}
