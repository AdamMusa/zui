import QtQuick
import Qt5Compat.GraphicalEffects

// QtQuick.Effects gained RectangularShadow in Qt 6.9; the pinned Qt 6.8.3
// exports only MultiEffect from that module, so the type this adapter used to
// instantiate does not exist and the component could not load at all.
//
// RectangularGlow draws the same primitive the Ruby surface describes: a
// blurred, colorized, rounded rectangle behind its children, independent of
// what those children look like. Its own shader expands past the item bounds
// (width + glowRadius * 2 + cornerRadius * 2, centred), so the shadow reaches
// outside this component without any padding of our own.
Item {
  id: shadowRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  // `spread` grows the shadow rectangle outwards in pixels. RectangularGlow's
  // own `spread` is a 0..1 colour weighting near the edges and cannot express
  // that, so the growth is geometric: the rectangle gets `spread` pixels on
  // every side, and a rounded rectangle grown by s has its corners grown by s
  // too.
  readonly property real shadowSpread: Number(renderer.prop("spread", 0))
  readonly property real shadowCornerRadius: Number(renderer.prop("radius", 0)) + shadowSpread

  // The glow is drawn by a fragment shader and is always smooth-edged, so
  // `antialiasing: false` is a request this implementation cannot honour.
  // Report it rather than accepting the property and ignoring it.
  function reportUnsupportedAntialiasing() {
    if (renderer.prop("antialiasing", true) !== false) return
    renderer.componentError("antialiasing_unsupported",
                            "rectangular_shadow is drawn by a shader and is always antialiased on Qt 6.8.3",
                            { antialiasing: false })
  }

  Component.onCompleted: shadowRoot.reportUnsupportedAntialiasing()
  Connections { target: renderer; function onNodeChanged() { shadowRoot.reportUnsupportedAntialiasing() } }

  RectangularGlow {
    x: Number(renderer.prop("offset_x", 0)) - shadowRoot.shadowSpread
    y: Number(renderer.prop("offset_y", 4)) - shadowRoot.shadowSpread
    width: shadowRoot.width + shadowRoot.shadowSpread * 2
    height: shadowRoot.height + shadowRoot.shadowSpread * 2
    glowRadius: Number(renderer.prop("blur", 20))
    cornerRadius: shadowRoot.shadowCornerRadius
    color: renderer.prop("color", "#80000000")
    cached: renderer.prop("cached", true) !== false
    spread: 0
  }

  Item {
    anchors.fill: parent
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
