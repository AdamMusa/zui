pragma Singleton
import QtQuick

QtObject {
  readonly property int cornerRadius: 10
  readonly property int normalBorderWidth: 1

  function space(value) { return Number(value) }
  function selectionFillFor(foreground, accent) { return Qt.rgba(accent.r, accent.g, accent.b, 0.34) }
  function hoverFillFor(foreground, accent) { return Qt.rgba(accent.r, accent.g, accent.b, 0.14) }
  function selectedFillFor(foreground, accent) { return Qt.rgba(accent.r, accent.g, accent.b, 0.22) }

  readonly property QtObject font: QtObject {
    readonly property string family: Fonts.family
    readonly property int caption: 11
    readonly property int bodySmall: 12
    readonly property int body: 14
    readonly property int subtitle: 16
    readonly property int heading: 20
    readonly property int display: 32
    readonly property int icon: 16
  }

  readonly property QtObject spacing: QtObject {
    readonly property int xs: 4
    readonly property int sm: 8
    readonly property int md: 12
    readonly property int lg: 16
    readonly property int xl: 24
    readonly property int panelGap: 10
    readonly property int controlGap: 8
    readonly property int controlHeight: 36
    readonly property int controlPaddingX: 12
    readonly property int controlPaddingY: 8
    readonly property int inputPaddingY: 8
    readonly property int rowPaddingX: 10
    readonly property int popupRowHeight: 36
    readonly property int searchablePopupMinHeight: 160
    readonly property int numberFieldWidth: 108
  }

  readonly property QtObject bar: QtObject {
    readonly property int iconSlot: 30
    readonly property int iconCanvas: 18
    readonly property int iconFont: 15
  }
}
