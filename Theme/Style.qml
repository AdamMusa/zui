pragma Singleton
import QtQuick

QtObject {
  readonly property int cornerRadius: 10
  readonly property int normalBorderWidth: 1

  function space(value) { return Number(value) }
  function selectionFillFor(foreground, accent) { return Qt.rgba(accent.r, accent.g, accent.b, 0.34) }
  function hoverFillFor(foreground, accent) { return Qt.rgba(accent.r, accent.g, accent.b, 0.14) }
  function selectedFillFor(foreground, accent) { return Qt.rgba(accent.r, accent.g, accent.b, 0.22) }

  // Qt Quick Controls already tracks a press in `down`, but an adapter that
  // overrides `background` has to paint it, and none of the adapters on a
  // navigation path did: pressing a sidebar entry drew nothing at all, so the
  // first visible answer to the click was the next page arriving, 85-230 ms
  // later on a light page and seconds on a heavy one. A press has to show in
  // the frame after the pointer goes down, which means deriving it from what
  // the control already paints rather than naming a colour in every adapter.
  //
  // Two cases cover the catalogue. A resting fill that is transparent or
  // barely there -- the default for a delegate, a tab button, a menu item and
  // every bar button -- has nothing to modify, so the press puts an accent
  // tint where there was nothing. Any other fill moves a third of the way
  // toward the accent, except one that is already the accent, which moves
  // toward the window background instead so that a filled accent button
  // still visibly dips.
  //
  // Both arguments must be resolved colours, not protocol strings;
  // ControlNode's pressedBackground() is what resolves them.
  readonly property real pressedTintAlpha: 0.3
  readonly property real pressedShift: 0.34

  function pressedTintFor(accent) {
    return Qt.rgba(accent.r, accent.g, accent.b, pressedTintAlpha)
  }

  function pressedFillFor(resting, accent) {
    if (resting.a < pressedTintAlpha) return pressedTintFor(accent)
    var target = colorsAlike(resting, accent) ? Color.background : accent
    return Qt.rgba(resting.r + (target.r - resting.r) * pressedShift,
                   resting.g + (target.g - resting.g) * pressedShift,
                   resting.b + (target.b - resting.b) * pressedShift,
                   resting.a)
  }

  function colorsAlike(first, second) {
    return Math.abs(first.r - second.r) + Math.abs(first.g - second.g)
      + Math.abs(first.b - second.b) < 0.2
  }

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
