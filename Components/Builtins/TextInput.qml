import QtQuick
import "../../Theme"
import "Support/TextInputHints.js" as Hints

Item {
  id: inputRoot
  required property var renderer
  property var activeValidator: null
  property string appliedValidatorKey: ""
  property int handledCommandRevision: -1
  property int handledSelectionRevision: -1
  implicitWidth: Number(renderer.prop("width", 200))
  implicitHeight: Number(renderer.prop("height", nativeInput.implicitHeight))

  function horizontalAlignment() {
    var requested = String(renderer.prop("horizontal_alignment", "left"))
    if (requested === "right") return TextInput.AlignRight
    if (requested === "center") return TextInput.AlignHCenter
    return TextInput.AlignLeft
  }

  function verticalAlignment() {
    var requested = String(renderer.prop("vertical_alignment", "top"))
    if (requested === "bottom") return TextInput.AlignBottom
    if (requested === "center") return TextInput.AlignVCenter
    return TextInput.AlignTop
  }

  function wrapMode() {
    var requested = String(renderer.prop("wrap", "none"))
    if (requested === "word") return TextInput.WordWrap
    if (requested === "anywhere") return TextInput.WrapAnywhere
    if (requested === "word_or_anywhere") return TextInput.WrapAtWordBoundaryOrAnywhere
    if (requested === "wrap") return TextInput.Wrap
    return TextInput.NoWrap
  }

  function echoMode() {
    var requested = String(renderer.prop("echo_mode", "normal"))
    if (requested === "no_echo") return TextInput.NoEcho
    if (requested === "password") return TextInput.Password
    if (requested === "password_echo_on_edit") return TextInput.PasswordEchoOnEdit
    return TextInput.Normal
  }

  function renderType() {
    var requested = String(renderer.prop("render_type", "qt"))
    if (requested === "native") return TextInput.NativeRendering
    if (requested === "curve") return TextInput.CurveRendering
    return TextInput.QtRendering
  }

  function validatorSpecification() {
    var requested = renderer.prop("validator", null)
    if (typeof requested === "string") return { type: requested }
    return requested && typeof requested === "object" ? requested : null
  }

  function rebuildValidator() {
    var specification = validatorSpecification()
    var key = specification ? JSON.stringify(specification) : ""
    if (key === appliedValidatorKey) return
    appliedValidatorKey = key
    var kind = specification && specification.type !== undefined ? String(specification.type) : ""
    nativeInput.validator = null
    if (activeValidator) {
      activeValidator.destroy()
      activeValidator = null
    }
    if (kind === "int") {
      activeValidator = intValidatorFactory.createObject(inputRoot, {
        bottom: Number(specification.bottom === undefined ? -2147483648 : specification.bottom),
        top: Number(specification.top === undefined ? 2147483647 : specification.top),
        locale: String(specification.locale === undefined ? Qt.locale().name : specification.locale)
      })
    } else if (kind === "double") {
      activeValidator = doubleValidatorFactory.createObject(inputRoot, {
        bottom: Number(specification.bottom === undefined ? -Number.MAX_VALUE : specification.bottom),
        top: Number(specification.top === undefined ? Number.MAX_VALUE : specification.top),
        decimals: Number(specification.decimals === undefined ? 1000 : specification.decimals),
        notation: String(specification.notation) === "standard"
          ? DoubleValidator.StandardNotation : DoubleValidator.ScientificNotation,
        locale: String(specification.locale === undefined ? Qt.locale().name : specification.locale)
      })
    } else if (kind === "regex") {
      var flags = ""
      if (specification.case_insensitive === true) flags += "i"
      if (specification.multiline === true) flags += "m"
      if (specification.dot_matches_newline === true) flags += "s"
      activeValidator = regexValidatorFactory.createObject(inputRoot, {
        regularExpression: new RegExp(String(specification.pattern === undefined ? "" : specification.pattern), flags)
      })
    } else if (kind !== "") {
      renderer.componentError("validator_rejected",
        "text_input accepts only int, double or regex validators", { requested: kind })
      return
    }
    nativeInput.validator = activeValidator
  }

  function applySelection() {
    var revision = Number(renderer.prop("selection_revision", 0))
    if (revision === handledSelectionRevision) return
    handledSelectionRevision = revision
    if (revision <= 0) return
    nativeInput.select(Number(renderer.prop("selection_start", 0)),
                       Number(renderer.prop("selection_end", 0)))
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", ""))
    if (command === "select_all") nativeInput.selectAll()
    else if (command === "select_word") nativeInput.selectWord()
    else if (command === "deselect") nativeInput.deselect()
    else if (command === "cut") nativeInput.cut()
    else if (command === "copy") nativeInput.copy()
    else if (command === "paste") nativeInput.paste()
    else if (command === "undo") nativeInput.undo()
    else if (command === "redo") nativeInput.redo()
    else if (command === "clear") nativeInput.text = ""
    else if (command === "focus") nativeInput.forceActiveFocus()
  }

  function synchronize() {
    rebuildValidator()
    applySelection()
    processCommand()
  }

  Component { id: intValidatorFactory; IntValidator {} }
  Component { id: doubleValidatorFactory; DoubleValidator {} }
  Component { id: regexValidatorFactory; RegularExpressionValidator {} }

  TextInput {
    id: nativeInput
    anchors.fill: parent
    text: String(renderer.prop("text", ""))
    color: renderer.prop("color", renderer.foreground)
    selectionColor: renderer.prop("selection_color", Color.accent)
    selectedTextColor: renderer.prop("selected_text_color", Color.background)
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    font.bold: renderer.prop("bold", false) === true
    font.italic: renderer.prop("italic", false) === true
    horizontalAlignment: inputRoot.horizontalAlignment()
    verticalAlignment: inputRoot.verticalAlignment()
    wrapMode: inputRoot.wrapMode()
    readOnly: renderer.prop("read_only", false) === true
    cursorVisible: renderer.prop("cursor_visible", true) !== false
    overwriteMode: renderer.prop("overwrite_mode", false) === true
    maximumLength: Number(renderer.prop("maximum_length", 32767))
    inputMask: String(renderer.prop("input_mask", ""))
    echoMode: inputRoot.echoMode()
    passwordCharacter: String(renderer.prop("password_character", "•"))
    passwordMaskDelay: Number(renderer.prop("password_mask_delay", 0))
    inputMethodHints: Hints.hints(renderer.prop("input_method_hints", null))
    EnterKey.type: Hints.enterKey(renderer.prop("enter_key", "default"))
    autoScroll: renderer.prop("auto_scroll", true) !== false
    selectByMouse: renderer.prop("select_by_mouse", true) !== false
    mouseSelectionMode: String(renderer.prop("mouse_selection_mode", "characters")) === "words"
      ? TextInput.SelectWords : TextInput.SelectCharacters
    persistentSelection: renderer.prop("persistent_selection", false) === true
    activeFocusOnPress: renderer.prop("active_focus_on_press", true) !== false
    renderType: inputRoot.renderType()
    padding: Number(renderer.prop("padding", 0))
    leftPadding: Number(renderer.prop("left_padding", padding))
    topPadding: Number(renderer.prop("top_padding", padding))
    rightPadding: Number(renderer.prop("right_padding", padding))
    bottomPadding: Number(renderer.prop("bottom_padding", padding))
    focus: renderer.prop("focus", false) === true

    onTextEdited: {
      if (renderer.subscribed("input"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", {
          value: text, display_text: displayText, acceptable: acceptableInput
        })
    }
    onTextChanged: {
      if (renderer.subscribed("change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
          value: text, display_text: displayText, length: length, acceptable: acceptableInput
        })
    }
    onAccepted: {
      if (renderer.subscribed("accept"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", { value: text })
    }
    onEditingFinished: {
      if (renderer.subscribed("editing_finished"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "editing_finished", { value: text })
    }
    onCursorPositionChanged: {
      if (renderer.subscribed("cursor_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cursor_change", {
          position: cursorPosition,
          rectangle: { x: cursorRectangle.x, y: cursorRectangle.y, width: cursorRectangle.width, height: cursorRectangle.height }
        })
    }
    onSelectedTextChanged: {
      if (renderer.subscribed("selection"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "selection", {
          start: selectionStart, end: selectionEnd, text: selectedText
        })
    }
    onAcceptableInputChanged: {
      if (renderer.subscribed("acceptable_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "acceptable_change", {
          acceptable: acceptableInput, value: text
        })
    }
    onPreeditTextChanged: {
      if (renderer.subscribed("preedit"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "preedit", {
          value: preeditText, composing: inputMethodComposing
        })
    }
    onActiveFocusChanged: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                                activeFocus ? "focus" : "blur", { value: text })
    }
  }

  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { inputRoot.synchronize() } }
}
