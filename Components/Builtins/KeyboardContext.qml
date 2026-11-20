import QtQuick
import QtQuick.VirtualKeyboard

Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  visible: false
  VirtualKeyboard.extraDictionaries: renderer.prop("extra_dictionaries", []) || []

  function rect(value) {
    return { x: Number(value.x), y: Number(value.y), width: Number(value.width), height: Number(value.height) }
  }

  function payload() {
    return {
      locale: String(InputContext.locale), uppercase: InputContext.uppercase,
      shift: InputContext.shift, caps_lock: InputContext.capsLock,
      shift_active: InputContext.shiftActive, caps_lock_active: InputContext.capsLockActive,
      cursor_position: InputContext.cursorPosition, anchor_position: InputContext.anchorPosition,
      surrounding_text: String(InputContext.surroundingText), selected_text: String(InputContext.selectedText),
      preedit_text: String(InputContext.preeditText), animating: InputContext.animating,
      input_method_hints: Number(InputContext.inputMethodHints),
      cursor_rectangle: rect(InputContext.cursorRectangle),
      anchor_rectangle: rect(InputContext.anchorRectangle),
      selection_control_visible: InputContext.selectionControlVisible === true,
      cursor_rect_clipped: InputContext.cursorRectIntersectsClipRect === true,
      anchor_rect_clipped: InputContext.anchorRectIntersectsClipRect === true,
      focused: InputContext.inputItem !== null
    }
  }

  function publish(eventName) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, payload())
  }

  // InputEngine is isCreatable: false and reached only as InputContext.inputEngine, so its
  // state is reported here rather than as a component of its own.
  function publishEngine() {
    var engine = InputContext.inputEngine
    if (!engine) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "engine", {
      input_mode: Number(engine.inputMode), input_modes: engine.inputModes,
      pattern_recognition_modes: engine.patternRecognitionModes,
      active_key: Number(engine.activeKey), previous_key: Number(engine.previousKey),
      word_candidate_list_visible: engine.wordCandidateListVisibleHint === true
    })
  }

  // SelectionListModel is isCreatable: false and reached only as the engine's
  // wordCandidateListModel. Its rows are read the way QML reads any model, so an
  // application can draw its own suggestion strip.
  function publishCandidates() {
    var candidates = []
    for (var index = 0; index < candidateRows.count; index++) {
      var row = candidateRows.itemAt(index)
      if (!row) continue
      candidates.push({ index: index, text: String(row.display),
        completion_length: Number(row.wordCompletionLength),
        dictionary: Number(row.dictionary),
        can_remove: row.canRemoveSuggestion === true })
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "candidates",
      { candidates: candidates, count: candidates.length })
  }

  // KeyboardObserver is only meaningful as InputContext.keyboardObserver, and that stays
  // null until an InputPanel exists, so the layout is reported when it becomes available.
  function publishLayout() {
    var observer = InputContext.keyboardObserver
    if (!observer || observer.layout === undefined) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "layout", { layout: observer.layout })
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", "commit"))
    if (command === "commit") {
      var replaceLength = Number(renderer.prop("replace_length", 0))
      if (replaceLength > 0)
        InputContext.commit(String(renderer.prop("text", "")), Number(renderer.prop("replace_from", 0)), replaceLength)
      else
        InputContext.commit(String(renderer.prop("text", "")))
      return
    }
    if (command === "key") {
      InputContext.sendKeyClick(Number(renderer.prop("key", 0)),
        String(renderer.prop("text", "")), Number(renderer.prop("modifiers", 0)))
      return
    }
    if (command === "clear") { InputContext.clear(); return }
    if (command === "input_mode") {
      var engine = InputContext.inputEngine
      if (!engine) {
        renderer.componentError("keyboard_engine_unavailable", "No virtual keyboard input engine is active", {})
        return
      }
      engine.inputMode = Number(renderer.prop("input_mode", 0))
      return
    }
    if (command === "invalidate_layout") {
      var observer = InputContext.keyboardObserver
      if (!observer || observer.invalidateLayout === undefined) {
        renderer.componentError("keyboard_observer_unavailable",
          "The keyboard layout observer is only available while an input panel exists", {})
        return
      }
      observer.invalidateLayout()
      return
    }
    renderer.componentError("keyboard_command_rejected", "The input context does not support the requested command",
      { command: command })
  }

  Repeater {
    id: candidateRows
    model: InputContext.inputEngine ? InputContext.inputEngine.wordCandidateListModel : 0
    delegate: Item {
      required property string display
      required property int wordCompletionLength
      required property int dictionary
      required property bool canRemoveSuggestion
    }
    onCountChanged: candidateTimer.restart()
  }
  // Candidates arrive one delegate at a time, so coalesce them into a single event.
  Timer { id: candidateTimer; interval: 16; repeat: false; onTriggered: root.publishCandidates() }

  Component.onCompleted: { publish("change"); publishEngine(); publishLayout(); processCommand() }
  Connections { target: renderer; function onNodeChanged() { root.processCommand() } }
  Connections {
    target: InputContext
    enabled: root.renderer.prop("watch", true) !== false
    function onLocaleChanged() { root.publish("locale_change") }
    function onSurroundingTextChanged() { root.publish("change") }
    function onSelectedTextChanged() { root.publish("change") }
    function onCursorPositionChanged() { root.publish("change") }
    function onCursorRectangleChanged() { root.publish("change") }
    function onShiftActiveChanged() { root.publish("change") }
    function onCapsLockActiveChanged() { root.publish("change") }
    function onSelectionControlVisibleChanged() { root.publish("change") }
    function onInputItemChanged() { root.publish("change"); root.publishLayout() }
  }
  Connections {
    target: InputContext.inputEngine
    enabled: root.renderer.prop("watch", true) !== false
    function onInputModeChanged() { root.publishEngine() }
    function onInputModesChanged() { root.publishEngine() }
    function onWordCandidateListVisibleHintChanged() { root.publishEngine() }
    function onActiveKeyChanged() { root.publishEngine() }
  }
}
