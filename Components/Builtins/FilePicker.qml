import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Dialogs
import "../../Theme"

QQC.Button {
  id: picker

  required property var renderer
  readonly property string mode: String(renderer.prop("mode", "open"))
  readonly property bool folderMode: mode === "folder" || mode === "directory"

  function fileUrl(path) {
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

  function selectedPaths() {
    var paths = renderer.prop("paths", [])
    if (Array.isArray(paths) && paths.length) return paths
    var path = String(renderer.prop("path", ""))
    return path.length ? [path] : []
  }

  function displayText() {
    var paths = selectedPaths()
    if (!paths.length) return String(renderer.prop("placeholder", folderMode ? "Choose a folder" : "Choose a file"))
    if (paths.length > 1) return paths.length + " files"
    var parts = String(paths[0]).split("/")
    return parts[parts.length - 1] || String(paths[0])
  }

  function emitSelection(paths) {
    var multiple = renderer.prop("multiple", false) === true
    var payload = multiple ? { values: paths, value: paths.length ? paths[0] : "" }
                           : { value: paths.length ? paths[0] : "" }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", payload)
  }

  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 40))
  enabled: renderer.prop("enabled", true) !== false
  onClicked: folderMode ? folderDialog.open() : fileDialog.open()

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

  FileDialog {
    id: fileDialog
    title: String(renderer.prop("title", mode === "save" ? "Save file" : "Choose file"))
    fileMode: mode === "save" ? FileDialog.SaveFile
      : (renderer.prop("multiple", false) === true ? FileDialog.OpenFiles : FileDialog.OpenFile)
    currentFile: picker.fileUrl(renderer.prop("path", ""))
    currentFiles: {
      var result = []
      var paths = renderer.prop("paths", [])
      if (Array.isArray(paths)) for (var index = 0; index < paths.length; index++) result.push(picker.fileUrl(paths[index]))
      return result
    }
    currentFolder: picker.fileUrl(renderer.prop("current_folder", ""))
    nameFilters: renderer.prop("filters", [])
    defaultSuffix: String(renderer.prop("default_suffix", ""))
    acceptLabel: String(renderer.prop("accept_text", ""))
    rejectLabel: String(renderer.prop("cancel_text", ""))
    visible: !folderMode && renderer.prop("opened", false) === true
    options: renderer.prop("native_dialog", true) === false ? FileDialog.DontUseNativeDialog : 0

    onAccepted: {
      var paths = []
      for (var index = 0; index < selectedFiles.length; index++) paths.push(picker.localPath(selectedFiles[index]))
      if (!paths.length && String(selectedFile).length) paths.push(picker.localPath(selectedFile))
      picker.emitSelection(paths)
    }
    onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {})
    onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      visible ? "open" : "close", {})
    onCurrentFolderChanged: {
      var value = picker.localPath(currentFolder)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "folder_change", { value: value })
    }
  }

  FolderDialog {
    id: folderDialog
    title: String(renderer.prop("title", "Choose folder"))
    currentFolder: picker.fileUrl(renderer.prop("current_folder", renderer.prop("path", "")))
    selectedFolder: picker.fileUrl(renderer.prop("path", ""))
    acceptLabel: String(renderer.prop("accept_text", ""))
    rejectLabel: String(renderer.prop("cancel_text", ""))
    visible: folderMode && renderer.prop("opened", false) === true
    options: renderer.prop("native_dialog", true) === false ? FolderDialog.DontUseNativeDialog : 0

    onAccepted: picker.emitSelection([picker.localPath(selectedFolder)])
    onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {})
    onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      visible ? "open" : "close", {})
    onCurrentFolderChanged: {
      var value = picker.localPath(currentFolder)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "folder_change", { value: value })
    }
  }
}
