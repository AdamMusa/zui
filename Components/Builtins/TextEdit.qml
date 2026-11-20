import QtQuick
import "../../Theme"
import "Support/TextInputHints.js" as Hints

Item {
  id: editRoot
  required property var renderer
  property int handledCommandRevision: -1
  property int handledSelectionRevision: -1
  property string appliedDocumentSource: ""
  property string appliedBaseUrl: ""
  implicitWidth: Number(renderer.prop("width", 320))
  implicitHeight: Number(renderer.prop("height", nativeEdit.implicitHeight))

  function horizontalAlignment() {
    var requested = String(renderer.prop("horizontal_alignment", "left"))
    if (requested === "right") return TextEdit.AlignRight
    if (requested === "center") return TextEdit.AlignHCenter
    if (requested === "justify") return TextEdit.AlignJustify
    return TextEdit.AlignLeft
  }

  function verticalAlignment() {
    var requested = String(renderer.prop("vertical_alignment", "top"))
    if (requested === "bottom") return TextEdit.AlignBottom
    if (requested === "center") return TextEdit.AlignVCenter
    return TextEdit.AlignTop
  }

  function wrapMode() {
    var requested = String(renderer.prop("wrap", "word"))
    if (requested === "none") return TextEdit.NoWrap
    if (requested === "anywhere") return TextEdit.WrapAnywhere
    if (requested === "word_or_anywhere") return TextEdit.WrapAtWordBoundaryOrAnywhere
    if (requested === "wrap") return TextEdit.Wrap
    return TextEdit.WordWrap
  }

  function textFormat() {
    var requested = String(renderer.prop("format", "plain"))
    if (requested === "rich") return TextEdit.RichText
    if (requested === "markdown") return TextEdit.MarkdownText
    if (requested === "auto") return TextEdit.AutoText
    return TextEdit.PlainText
  }

  function renderType() {
    var requested = String(renderer.prop("render_type", "qt"))
    if (requested === "native") return TextEdit.NativeRendering
    if (requested === "curve") return TextEdit.CurveRendering
    return TextEdit.QtRendering
  }

  function documentStatusName(status) {
    if (status === TextDocument.Loading) return "loading"
    if (status === TextDocument.Loaded) return "loaded"
    if (status === TextDocument.Saving) return "saving"
    if (status === TextDocument.Saved) return "saved"
    if (status === TextDocument.ReadError) return "read_error"
    if (status === TextDocument.WriteError) return "write_error"
    if (status === TextDocument.NonLocalFileError) return "non_local_file_error"
    return "null"
  }

  function applySelection() {
    var revision = Number(renderer.prop("selection_revision", 0))
    if (revision === handledSelectionRevision) return
    handledSelectionRevision = revision
    if (revision <= 0) return
    nativeEdit.select(Number(renderer.prop("selection_start", 0)),
                      Number(renderer.prop("selection_end", 0)))
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", ""))
    if (command === "select_all") nativeEdit.selectAll()
    else if (command === "select_word") nativeEdit.selectWord()
    else if (command === "deselect") nativeEdit.deselect()
    else if (command === "cut") nativeEdit.cut()
    else if (command === "copy") nativeEdit.copy()
    else if (command === "paste") nativeEdit.paste()
    else if (command === "undo") nativeEdit.undo()
    else if (command === "redo") nativeEdit.redo()
    else if (command === "clear") nativeEdit.clear()
    else if (command === "focus") nativeEdit.forceActiveFocus()
    else if (command === "save") nativeEdit.textDocument.save()
    else if (command === "save_as") nativeEdit.textDocument.saveAs(String(renderer.prop("source", "")))
  }

  function applyDocumentSource() {
    var requested = String(renderer.prop("source", ""))
    if (requested === "" || requested === appliedDocumentSource) return
    appliedDocumentSource = requested
    nativeEdit.textDocument.source = Qt.url(requested)
  }

  function applyBaseUrl() {
    var requested = String(renderer.prop("base_url", ""))
    if (requested === "" || requested === appliedBaseUrl) return
    appliedBaseUrl = requested
    nativeEdit.baseUrl = Qt.url(requested)
  }

  function synchronize() {
    applyBaseUrl()
    applyDocumentSource()
    applySelection()
    processCommand()
  }

  TextEdit {
    id: nativeEdit
    anchors.fill: parent
    text: String(renderer.prop("text", ""))
    color: renderer.prop("color", renderer.foreground)
    selectionColor: renderer.prop("selection_color", Color.accent)
    selectedTextColor: renderer.prop("selected_text_color", Color.background)
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    font.bold: renderer.prop("bold", false) === true
    font.italic: renderer.prop("italic", false) === true
    horizontalAlignment: editRoot.horizontalAlignment()
    verticalAlignment: editRoot.verticalAlignment()
    wrapMode: editRoot.wrapMode()
    textFormat: editRoot.textFormat()
    readOnly: renderer.prop("read_only", false) === true
    cursorVisible: renderer.prop("cursor_visible", true) !== false
    overwriteMode: renderer.prop("overwrite_mode", false) === true
    textMargin: Number(renderer.prop("text_margin", 0))
    tabStopDistance: Number(renderer.prop("tab_stop_distance", 80))
    inputMethodHints: Hints.hints(renderer.prop("input_method_hints", null))
    EnterKey.type: Hints.enterKey(renderer.prop("enter_key", "default"))
    selectByKeyboard: renderer.prop("select_by_keyboard", true) !== false
    selectByMouse: renderer.prop("select_by_mouse", true) !== false
    mouseSelectionMode: String(renderer.prop("mouse_selection_mode", "characters")) === "words"
      ? TextEdit.SelectWords : TextEdit.SelectCharacters
    persistentSelection: renderer.prop("persistent_selection", false) === true
    activeFocusOnPress: renderer.prop("active_focus_on_press", true) !== false
    renderType: editRoot.renderType()
    padding: Number(renderer.prop("padding", 0))
    leftPadding: Number(renderer.prop("left_padding", padding))
    topPadding: Number(renderer.prop("top_padding", padding))
    rightPadding: Number(renderer.prop("right_padding", padding))
    bottomPadding: Number(renderer.prop("bottom_padding", padding))
    focus: renderer.prop("focus", false) === true

    onTextChanged: {
      if (renderer.subscribed("change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
          value: text, length: length, line_count: lineCount
        })
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
    onContentSizeChanged: {
      if (renderer.subscribed("content_size"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "content_size", {
          width: contentWidth, height: contentHeight,
          painted_width: paintedWidth, painted_height: paintedHeight
        })
    }
    onPreeditTextChanged: {
      if (renderer.subscribed("preedit"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "preedit", {
          value: preeditText, composing: inputMethodComposing
        })
    }
    onLinkActivated: function (link) {
      if (renderer.subscribed("link"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "link", { value: String(link) })
    }
    onLinkHovered: function (link) {
      if (renderer.subscribed("link_hover"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "link_hover", { value: String(link) })
    }
    onActiveFocusChanged: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                                activeFocus ? "focus" : "blur", { value: text })
    }
  }

  Connections {
    target: nativeEdit.textDocument
    function onStatusChanged() {
      var status = nativeEdit.textDocument.status
      if (status === TextDocument.ReadError || status === TextDocument.WriteError
          || status === TextDocument.NonLocalFileError) {
        editRoot.renderer.componentError("text_document_failed",
          String(nativeEdit.textDocument.errorString),
          { status: editRoot.documentStatusName(status) })
        return
      }
      if (!editRoot.renderer.subscribed("document_status")) return
      editRoot.renderer.bridge.sendEvent(editRoot.renderer.surfaceName, editRoot.renderer.controlId,
        "document_status", { value: editRoot.documentStatusName(status),
                             source: String(nativeEdit.textDocument.source) })
    }
    function onModifiedChanged() {
      if (!editRoot.renderer.subscribed("modified")) return
      editRoot.renderer.bridge.sendEvent(editRoot.renderer.surfaceName, editRoot.renderer.controlId,
        "modified", { value: nativeEdit.textDocument.modified })
    }
  }

  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { editRoot.synchronize() } }
}
