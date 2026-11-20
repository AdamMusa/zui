import QtQuick
import QtQuick.Effects

// Qt's own RectangularShadow arrived in 6.9. Naming this file after it made
// the type resolve to this very file on every older Qt, so the adapter
// instantiated itself without end: the window stopped answering, the process
// sat at 100% of a core, and the only trace was one line of QML warning. The
// shadow is cast here instead, from a rounded rectangle grown by the spread
// and blurred with MultiEffect, which has shipped since 6.5.
Item {
  id: shadowRoot
  required property var renderer
  readonly property real blurRadius: Math.max(0, Number(renderer.prop("blur", 20)))
  readonly property real spread: Math.max(0, Number(renderer.prop("spread", 0)))
  readonly property real cornerRadius: Math.max(0, Number(renderer.prop("radius", 0)))
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  Rectangle {
    id: caster
    x: -shadowRoot.spread
    y: -shadowRoot.spread
    width: shadowRoot.width + shadowRoot.spread * 2
    height: shadowRoot.height + shadowRoot.spread * 2
    radius: shadowRoot.cornerRadius + shadowRoot.spread
    color: shadowRoot.renderer.prop("color", "#80000000")
    antialiasing: shadowRoot.renderer.prop("antialiasing", true) !== false
    visible: false
    layer.enabled: true
    layer.smooth: shadowRoot.renderer.prop("cached", true) !== false
  }

  MultiEffect {
    source: caster
    x: caster.x + Number(shadowRoot.renderer.prop("offset_x", 0))
    y: caster.y + Number(shadowRoot.renderer.prop("offset_y", 4))
    width: caster.width
    height: caster.height
    blurEnabled: shadowRoot.blurRadius > 0
    blur: 1.0
    blurMax: Math.min(64, Math.max(2, Math.round(shadowRoot.blurRadius)))
    autoPaddingEnabled: true
  }

  Item {
    anchors.fill: parent
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
