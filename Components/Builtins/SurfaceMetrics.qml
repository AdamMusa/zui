import QtQuick
import QtQuick.Window

// An application had no way to find out how much room it had been given. An
// `app` surface is a plain container, not an application_window, so no resize
// ever reached Ruby, and safe_area reports only the insets the platform asks
// for. Every dimension in a Zui application therefore had to be a constant,
// and a resized window either clipped the layout or left dead space beside it.
//
// This reports the room the application's root control actually occupies —
// the window minus the inset the shell leaves around it — and the window
// itself alongside, because a layout sometimes wants to know about the chrome
// it does not own. It draws nothing and takes no space.
Item {
  id: root
  required property var renderer
  visible: false
  implicitWidth: 0
  implicitHeight: 0

  readonly property var hostWindow: Window.window
  // Desktop.qml publishes the content geometry because it is the only thing
  // that knows the inset it applied. Falling back to the window's own size
  // keeps this working inside a surface that does not inset its root.
  readonly property real contentWidth: hostWindow
    ? Number(hostWindow.zuiContentWidth !== undefined ? hostWindow.zuiContentWidth : hostWindow.width)
    : 0
  readonly property real contentHeight: hostWindow
    ? Number(hostWindow.zuiContentHeight !== undefined ? hostWindow.zuiContentHeight : hostWindow.height)
    : 0

  function metrics() {
    return {
      width: Math.round(root.contentWidth),
      height: Math.round(root.contentHeight),
      window_width: root.hostWindow ? Math.round(root.hostWindow.width) : 0,
      window_height: root.hostWindow ? Math.round(root.hostWindow.height) : 0,
      pixel_ratio: Number(Screen.devicePixelRatio) || 1,
      orientation: root.contentWidth >= root.contentHeight ? "landscape" : "portrait"
    }
  }

  function publish() {
    if (!renderer || !renderer.bridge) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", root.metrics())
  }

  // A drag resizes the window continuously, and every pixel of it would other-
  // wise be a protocol message and a full re-evaluation of whatever the
  // application binds to the size. Coalescing to one message per idle moment
  // keeps a drag cheap; `interval` lets an application that wants every frame
  // ask for it.
  Timer {
    id: settle
    interval: Math.max(0, Number(renderer ? renderer.prop("interval", 80) : 80))
    repeat: false
    onTriggered: root.publish()
  }

  onContentWidthChanged: settle.restart()
  onContentHeightChanged: settle.restart()
  Component.onCompleted: publish()

  Connections {
    target: renderer
    function onNodeChanged() {
      var requested = Number(root.renderer.prop("refresh_revision", 0))
      if (requested === root.handledRefreshRevision) return
      root.handledRefreshRevision = requested
      root.publish()
    }
  }
  property int handledRefreshRevision: 0
}
