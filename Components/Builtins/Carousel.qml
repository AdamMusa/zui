import QtQuick
import QtQuick.Window
import "../../Theme"
import "Support" as Support

Rectangle {
  id: carouselRoot
  property var renderer: null
  readonly property var items: renderer ? renderer.prop("items", []) : []
  property var createdElements: []
  property string appliedElementKey: ""
  property int handledCommandRevision: -1
  implicitWidth: Number(renderer ? renderer.prop("width", 640) : 640)
  implicitHeight: Number(renderer ? renderer.prop("height", 320) : 320)
  color: renderer ? renderer.prop("background", "transparent") : "transparent"

  function field(item, propertyName, fallback) {
    if (item !== null && typeof item === "object" && !Array.isArray(item)) {
      var key = String(renderer.prop(propertyName, fallback)); return item[key]
    }
    return item
  }

  function highlightRangeMode() {
    // snap_mode has always driven highlightRangeMode here, with highlight-range
    // words rather than Qt's SnapMode words. highlight_range_mode is the
    // correctly named property; snap_mode stays as its legacy spelling so no
    // existing carousel changes meaning. Qt's real snapMode is item_snap_mode.
    var mode = String(renderer.prop("highlight_range_mode", renderer.prop("snap_mode", "strict")))
    if (mode === "none") return PathView.NoHighlightRange
    if (mode === "apply") return PathView.ApplyRange
    return PathView.StrictlyEnforceRange
  }

  function itemSnapMode() {
    var mode = String(renderer.prop("item_snap_mode", "no_snap"))
    if (mode === "item" || mode === "snap_to_item") return PathView.SnapToItem
    if (mode === "one_item" || mode === "snap_one_item") return PathView.SnapOneItem
    return PathView.NoSnap
  }

  function movementDirection() {
    var mode = String(renderer.prop("movement_direction", "shortest"))
    if (mode === "negative") return PathView.Negative
    if (mode === "positive") return PathView.Positive
    return PathView.Shortest
  }

  function highlightBound(index, fallback) {
    var value = renderer.prop("highlight_range", fallback)
    if (!Array.isArray(value)) return Number(value)
    return Number(index === 0 ? value[0] : value[value.length - 1])
  }

  function rebuildPath() {
    var segments = renderer.prop("path_segments", null)
    var data = String(renderer.prop("path_data", ""))
    var key = JSON.stringify({ segments: segments, data: data })
    if (key === appliedElementKey) return
    appliedElementKey = key
    carouselPath.pathElements = []
    for (var existing = 0; existing < createdElements.length; existing++) createdElements[existing].destroy()
    if (Array.isArray(segments) && segments.length > 0) {
      var built = segmentFactory.build(carouselRoot, segments)
      createdElements = built.elements
      if (built.rejected.length > 0)
        renderer.componentError("carousel_path_rejected",
          "carousel accepts only the Qt path element types", { types: built.rejected })
    } else if (data !== "") {
      createdElements = [svgFactory.createObject(carouselRoot, { path: data })]
    } else {
      // No path given: keep the arc this component has always drawn.
      createdElements = [defaultArcFactory.createObject(carouselRoot)]
    }
    carouselPath.pathElements = createdElements
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", ""))
    if (command === "increment") pathControl.incrementCurrentIndex()
    else if (command === "decrement") pathControl.decrementCurrentIndex()
    else if (command === "refill") pathControl.refill()
  }

  // offset is driven by interaction and maximumFlickVelocity defaults to the
  // platform theme, so neither is bound: they are written only when asked for.
  function applyOptionalViewProperties() {
    if (renderer.hasProp("offset")) pathControl.offset = Number(renderer.prop("offset", 0))
    if (renderer.hasProp("maximum_flick_velocity"))
      pathControl.maximumFlickVelocity = Number(renderer.prop("maximum_flick_velocity", 0))
  }

  function synchronize() {
    rebuildPath()
    applyOptionalViewProperties()
    processCommand()
  }

  Support.PathSegmentFactory { id: segmentFactory }
  Component { id: svgFactory; PathSvg {} }
  Component {
    id: defaultArcFactory
    PathCubic {
      x: carouselRoot.width
      y: carouselRoot.height / 2
      control1X: carouselRoot.width * 0.25
      control1Y: carouselRoot.height / 2 - Number(carouselRoot.renderer.prop("path_radius", 72))
      control2X: carouselRoot.width * 0.75
      control2Y: carouselRoot.height / 2 - Number(carouselRoot.renderer.prop("path_radius", 72))
    }
  }

  PathView {
    id: pathControl
    anchors.fill: parent
    model: carouselRoot.items
    currentIndex: Number(renderer.prop("current_index", 0))
    interactive: renderer.prop("interactive", true) !== false
    preferredHighlightBegin: carouselRoot.highlightBound(0, 0.5)
    preferredHighlightEnd: carouselRoot.highlightBound(1, 0.5)
    highlightRangeMode: carouselRoot.highlightRangeMode()
    highlightMoveDuration: Number(renderer.prop("highlight_move_duration", 300))
    snapMode: carouselRoot.itemSnapMode()
    movementDirection: carouselRoot.movementDirection()
    dragMargin: Number(renderer.prop("drag_margin", 0))
    flickDeceleration: Number(renderer.prop("flick_deceleration", 100))
    cacheItemCount: Number(renderer.prop("cache_item_count", 0))
    pathItemCount: Number(renderer.prop("path_item_count", Math.min(carouselRoot.items.length, 7)))
    path: Path {
      id: carouselPath
      startX: Number(renderer.prop("path_start_x", 0))
      startY: Number(renderer.prop("path_start_y", carouselRoot.height / 2))
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
          sourceSize.width: Util.scalableImageSourceSize(source, -1, width, Screen.devicePixelRatio)
          sourceSize.height: Util.scalableImageSourceSize(source, -1, height, Screen.devicePixelRatio)
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
    onFlickStarted: {
      if (renderer.subscribed("flick_start"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "flick_start", { offset: offset })
    }
    onFlickEnded: {
      if (renderer.subscribed("flick_end"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "flick_end", { offset: offset, value: currentIndex })
    }
    onDragStarted: {
      if (renderer.subscribed("drag_start"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag_start", { offset: offset })
    }
    onDragEnded: {
      if (renderer.subscribed("drag_end"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag_end", { offset: offset, value: currentIndex })
    }
    onOffsetChanged: {
      if (renderer.subscribed("offset_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "offset_change", {
          value: offset, moving: moving, flicking: flicking, dragging: dragging
        })
    }
    onCountChanged: {
      if (renderer.subscribed("count_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "count_change", { value: count })
    }
  }

  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { carouselRoot.synchronize() } }
}
