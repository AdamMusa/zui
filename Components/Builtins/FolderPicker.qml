import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Dialogs
import "../../Theme"

QQC.Button {
  id: picker

  required property var renderer

  function folderUrl(path) {
    var value = String(path || "")
    if (!value.length) return ""
    if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(value)) return value
    return "file://" + encodeURI(value.charAt(0) === "/" ? value : "/" + value)
  }

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.substring(7)
    return decodeURIComponent(value)
  }

  function displayText() {
    var path = String(renderer.prop("path", ""))
    if (!path.length) return String(renderer.prop("placeholder", "Choose a folder"))
    var parts = path.split("/")
    return parts[parts.length - 1] || path
  }

  function emitSelection(path) {
    var payload = { value: path }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", payload)
  }

  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 40))
  enabled: renderer.prop("enabled", true) !== false
  onClicked: folderDialog.open()

  background: Rectangle {
    color: renderer.prop("background", Color.popups.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Style.normalBorderWidth
    border.color: picker.activeFocus
      ? renderer.prop("accent", Color.accent)
      : renderer.prop("border_color", renderer.foreground)
    opacity: picker.down ? 0.72 : 1
  }

  contentItem: Row {
    spacing: Style.spacing.controlGap
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: String(renderer.prop("label", ""))
      visible: text.length > 0
      color: renderer.prop("muted", Color.muted)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, picker.availableWidth - x)
      text: picker.displayText()
      elide: Text.ElideMiddle
      color: renderer.prop("foreground", renderer.foreground)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    }
  }

  FolderDialog {
    id: folderDialog
    title: String(renderer.prop("title", "Choose folder"))
    currentFolder: picker.folderUrl(renderer.prop("current_folder", renderer.prop("path", "")))
    selectedFolder: picker.folderUrl(renderer.prop("path", ""))
    acceptLabel: String(renderer.prop("accept_text", ""))
    rejectLabel: String(renderer.prop("cancel_text", ""))
    visible: renderer.prop("opened", false) === true
    options: renderer.prop("native_dialog", true) === false ? FolderDialog.DontUseNativeDialog : 0

    onAccepted: picker.emitSelection(picker.localPath(selectedFolder))
    onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {})
    onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      visible ? "open" : "close", {})
    onCurrentFolderChanged: {
      var value = picker.localPath(currentFolder)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "folder_change", { value: value })
    }
  }
}
