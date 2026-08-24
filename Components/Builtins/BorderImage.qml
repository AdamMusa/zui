import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

BorderImage {
  required property var renderer
      id: nativeBorderImage
      source: String(renderer.prop("source", ""))
      width: Number(renderer.prop("width", sourceSize.width > 0 ? sourceSize.width : 160))
      height: Number(renderer.prop("height", sourceSize.height > 0 ? sourceSize.height : 100))
      border.left: Number(renderer.prop("border_left", 0))
      border.top: Number(renderer.prop("border_top", 0))
      border.right: Number(renderer.prop("border_right", 0))
      border.bottom: Number(renderer.prop("border_bottom", 0))
      horizontalTileMode: renderer.borderImageTileMode(renderer.prop("horizontal_tile", "stretch"))
      verticalTileMode: renderer.borderImageTileMode(renderer.prop("vertical_tile", "stretch"))
      asynchronous: renderer.prop("asynchronous", true) !== false
      cache: renderer.prop("cache", true) !== false
      mirror: renderer.prop("mirror", false) === true
      smooth: renderer.prop("smooth", true) !== false
      onStatusChanged: {
        if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status })
        if (status === BorderImage.Ready && renderer.subscribed("loaded")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "loaded", { width: sourceSize.width, height: sourceSize.height })
        if (status === BorderImage.Error) renderer.componentError("border_image_load_failed", "Unable to load the declared border image", { source: String(source) })
      }
      Item {
        anchors.fill: parent
        anchors.leftMargin: nativeBorderImage.border.left
        anchors.topMargin: nativeBorderImage.border.top
        anchors.rightMargin: nativeBorderImage.border.right
        anchors.bottomMargin: nativeBorderImage.border.bottom
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
