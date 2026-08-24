import QtQuick
import QtQuick.Controls as QQC
import "Theme"

QQC.ApplicationWindow {
  id: window

  readonly property string activeSurface: applicationSurface()
  readonly property var windowOptions: service.optionsFor(activeSurface)

  function option(name, fallback) {
    var value = windowOptions ? windowOptions[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function applicationSurface() {
    if (service.rootId("main") !== "") return "main"
    var names = Object.keys(service.surfaces)
    return names.length > 0 ? names[0] : ""
  }

  visible: option("visible", true) !== false
  title: String(option("title", zuiApplicationName))
  width: Number(option("width", 760))
  height: Number(option("height", 520))
  minimumWidth: Number(option("min_width", 320))
  minimumHeight: Number(option("min_height", 220))
  maximumWidth: Number(option("max_width", 16777215))
  maximumHeight: Number(option("max_height", 16777215))
  visibility: option("fullscreen", false) === true
    ? Window.FullScreen
    : (option("maximized", false) === true ? Window.Maximized : Window.Windowed)
  color: option("color", Color.background)

  Service {
    id: service
    transport: zuiProcess
    projectDir: zuiProjectDir
    componentDir: zuiComponentDir
    runtimeExecutable: zuiRubyExecutable
    program: zuiRubyProgram
    rubyLoadPath: zuiRubyLoadPath
  }

  ControlNode {
    id: renderer
    anchors.fill: parent
    anchors.margins: Number(window.option("padding", 20))
    visible: Fonts.ready && window.activeSurface !== "" && service.rootId(window.activeSurface) !== ""
    bridge: service
    surfaceName: window.activeSurface
    controlId: service.rootId(surfaceName)
    foreground: Color.foreground
    fontFamily: Style.font.family
  }

  Column {
    anchors.centerIn: parent
    spacing: Style.spacing.sm
    visible: !renderer.visible
    QQC.BusyIndicator {
      anchors.horizontalCenter: parent.horizontalCenter
      running: (!service.ready || !Fonts.ready) && service.lastError === "" && !Fonts.failed
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: service.lastError !== "" ? service.lastError
        : (Fonts.failed ? "Zui could not load its bundled fonts" : "Starting Zui…")
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }

  onClosing: function(close) {
    service.stopping = true
    if (zuiProcess.running) zuiProcess.stop()
    close.accepted = true
  }
}
