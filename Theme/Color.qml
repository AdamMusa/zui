pragma Singleton
import QtQuick

QtObject {
  readonly property color background: "#0b1118"
  readonly property color foreground: "#edf5f7"
  readonly property color accent: "#59e1ff"
  readonly property color muted: "#78909c"
  readonly property color urgent: "#ff5d7a"
  readonly property color border: "#29404c"

  readonly property QtObject popups: QtObject {
    readonly property color background: "#111c26"
    readonly property color border: "#2c4654"
  }

  readonly property QtObject tooltip: QtObject {
    readonly property color background: "#172631"
    readonly property color text: "#f4fbfd"
    readonly property color border: "#355363"
  }
}
