import QtQuick
import QtTest
import "../../Theme"

// Qt Quick Controls tracks a press in `down`; an adapter that overrides
// `background` has to paint it. These cases load the real adapter with a real
// ControlNode behind it, press it with a synthesised mouse event and read the
// painted pixels back, so they fail if an adapter stops answering a press
// locally -- which is a thing no string match on the source can see.
Item {
  id: harness
  width: 420
  height: 120

  // ControlNode with a bridge that knows nothing: every prop() falls back,
  // which is exactly the appearance an application gets before it sets
  // anything, and pressedBackground()/pressedForeground() are the real ones.
  // The two font properties are assigned rather than bound because Theme/Fonts
  // reads context properties that only the native client installs.
  Loader {
    id: rendererLoader
    source: Qt.resolvedUrl("../../ControlNode.qml")
    onLoaded: {
      item.bridge = silentBridge
      item.fontFamily = "Helvetica"
      item.foreground = Color.foreground
    }
  }

  QtObject {
    id: silentBridge
    property int revision: 0
    property string projectDir: ""
    function nodeFor(controlId) { return null }
    function componentDefinition(typeName) { return null }
    function componentSource(typeName) { return "" }
    function sendEvent(surfaceName, controlId, eventName, payload) {}
    function reportComponentError(surfaceName, controlId, componentType, code, message) {}
  }

  Rectangle {
    id: stage
    anchors.fill: parent
    color: Color.background

    Loader {
      id: adapterLoader
      x: 20
      y: 20
    }
  }

  TestCase {
    id: testCase
    name: "PressedFeedback"
    when: windowShown

    // Each row is sized the way the adapter asks to be sized, and probes a
    // pixel inside its fill but clear of its label and its indicator.
    function pressedAdapters() {
      return [
        { file: "ItemDelegate.qml", width: 320, height: 56, probe: Qt.point(8, 28) },
        { file: "CheckDelegate.qml", width: 320, height: 56, probe: Qt.point(8, 28) },
        { file: "RadioDelegate.qml", width: 320, height: 56, probe: Qt.point(8, 28) },
        { file: "SwitchDelegate.qml", width: 320, height: 56, probe: Qt.point(8, 28) },
        { file: "SwipeDelegate.qml", width: 360, height: 60, probe: Qt.point(8, 30) },
        { file: "TabButton.qml", width: 140, height: 44, probe: Qt.point(6, 22) },
        { file: "MenuItem.qml", width: 240, height: 42, probe: Qt.point(8, 21) },
        { file: "Button.qml", width: 120, height: 44, probe: Qt.point(8, 22) },
        { file: "Chip.qml", width: 90, height: 30, probe: Qt.point(14, 15) },
        { file: "ToolButton.qml", width: 40, height: 36, probe: Qt.point(6, 18) },
        { file: "RoundButton.qml", width: 44, height: 44, probe: Qt.point(22, 6) },
        { file: "ActionButton.qml", width: 28, height: 28, probe: Qt.point(14, 4) },
        { file: "BarIconButton.qml", width: 30, height: 30, probe: Qt.point(4, 15) },
        { file: "WidgetButton.qml", width: 60, height: 28, probe: Qt.point(4, 14) }
      ]
    }

    function probePixel(image, row) {
      return image.pixel(adapterLoader.x + row.probe.x, adapterLoader.y + row.probe.y)
    }

    function loadAdapter(row) {
      adapterLoader.width = row.width
      adapterLoader.height = row.height
      adapterLoader.setSource(Qt.resolvedUrl("../../Components/Builtins/" + row.file),
        { renderer: rendererLoader.item })
      tryCompare(adapterLoader, "status", Loader.Ready, 2000)
      verify(adapterLoader.item !== null, row.file + " did not load")
      wait(0)
    }

    function test_a_press_repaints_without_a_round_trip_data() {
      return pressedAdapters()
    }

    // The number that matters is how long a user waits between pressing and
    // seeing something. grabImage() renders synchronously, so the interval
    // around it is press-to-painted.
    function test_a_press_repaints_without_a_round_trip(row) {
      loadAdapter(row)
      var item = adapterLoader.item
      var restingPixel = probePixel(grabImage(stage), row)

      var started = Date.now()
      mousePress(item, item.width / 2, item.height / 2)
      var pressedPixel = probePixel(grabImage(stage), row)
      var elapsed = Date.now() - started
      mouseRelease(item, item.width / 2, item.height / 2)

      console.info(row.file + ": resting " + restingPixel + " pressed " + pressedPixel
        + " press-to-painted " + elapsed + " ms")
      verify(restingPixel !== pressedPixel,
        row.file + " painted nothing while held down (" + restingPixel + ")")
      compare(probePixel(grabImage(stage), row), restingPixel,
        row.file + " kept its pressed fill after the release")
    }
  }
}
