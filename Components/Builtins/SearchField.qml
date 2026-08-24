import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.TextField {
  id: nativeSearchField
  required property var renderer

  readonly property var suggestionModel: renderer.prop("suggestions", [])
  readonly property string textRole: String(renderer.prop("text_role", ""))
  readonly property bool live: renderer.prop("live", false) === true
  property int highlightedIndex: Number(renderer.prop("current_index", -1))

  function suggestionText(entry) {
    if (entry !== null && typeof entry === "object") {
      if (textRole.length > 0 && entry[textRole] !== undefined) return String(entry[textRole])
      if (entry.label !== undefined) return String(entry.label)
      if (entry.text !== undefined) return String(entry.text)
      if (entry.value !== undefined) return String(entry.value)
    }
    return String(entry === null || entry === undefined ? "" : entry)
  }

  function sendSearch() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "search", { value: text })
  }

  function highlightSuggestion(index) {
    if (!Array.isArray(suggestionModel) || suggestionModel.length === 0) return
    highlightedIndex = Math.max(0, Math.min(suggestionModel.length - 1, index))
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "highlight",
      { index: highlightedIndex, value: suggestionText(suggestionModel[highlightedIndex]) })
    suggestionList.positionViewAtIndex(highlightedIndex, ListView.Contain)
  }

  function activateSuggestion(index) {
    if (!Array.isArray(suggestionModel) || index < 0 || index >= suggestionModel.length) return
    highlightedIndex = index
    text = suggestionText(suggestionModel[index])
    suggestionPopup.close()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate",
      { index: index, value: text })
  }

  function synchronizePopup() {
    if (activeFocus && Array.isArray(suggestionModel) && suggestionModel.length > 0)
      suggestionPopup.open()
    else
      suggestionPopup.close()
  }

  text: String(renderer.prop("text", ""))
  enabled: renderer.prop("enabled", true) !== false
  implicitWidth: Number(renderer.prop("width", 260))
  leftPadding: 38
  rightPadding: text.length > 0 ? 38 : 12
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  color: renderer.prop("foreground", renderer.foreground)
  selectionColor: renderer.prop("accent", Color.accent)
  selectedTextColor: Color.background
  background: Rectangle {
    color: renderer.prop("background", Color.popups.background)
    radius: Style.cornerRadius
    border.width: Style.normalBorderWidth
    border.color: nativeSearchField.activeFocus
      ? renderer.prop("accent", Color.accent)
      : renderer.prop("foreground", renderer.foreground)
  }

  onTextEdited: {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: text })
    if (live) sendSearch()
    synchronizePopup()
  }
  onAccepted: {
    if (suggestionPopup.opened && highlightedIndex >= 0)
      activateSuggestion(highlightedIndex)
    else
      suggestionPopup.close()
    sendSearch()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "submit", { value: text })
  }
  onActiveFocusChanged: {
    synchronizePopup()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      activeFocus ? "focus" : "blur", { value: text })
    if (!activeFocus && renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: text })
  }
  onSuggestionModelChanged: synchronizePopup()

  Keys.onDownPressed: function(event) {
    highlightSuggestion(highlightedIndex < 0 ? 0 : highlightedIndex + 1)
    suggestionPopup.open()
    event.accepted = true
  }
  Keys.onUpPressed: function(event) {
    highlightSuggestion(highlightedIndex < 0 ? suggestionModel.length - 1 : highlightedIndex - 1)
    suggestionPopup.open()
    event.accepted = true
  }
  Keys.onEscapePressed: function(event) {
    suggestionPopup.close()
    event.accepted = true
  }

  QQC.ToolButton {
    id: searchButton
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 34
    height: parent.height
    text: "⌕"
    focusPolicy: Qt.NoFocus
    palette.buttonText: renderer.prop("foreground", renderer.foreground)
    onClicked: nativeSearchField.sendSearch()
  }

  QQC.ToolButton {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 34
    height: parent.height
    visible: nativeSearchField.text.length > 0
    text: "×"
    focusPolicy: Qt.NoFocus
    palette.buttonText: renderer.prop("foreground", renderer.foreground)
    onClicked: {
      nativeSearchField.text = ""
      nativeSearchField.forceActiveFocus()
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "clear", {})
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: "" })
      if (nativeSearchField.live) nativeSearchField.sendSearch()
    }
  }

  QQC.Popup {
    id: suggestionPopup
    parent: nativeSearchField
    x: 0
    y: nativeSearchField.height + 4
    width: nativeSearchField.width
    height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, 280)
    padding: 4
    closePolicy: QQC.Popup.CloseOnEscape | QQC.Popup.CloseOnPressOutsideParent
    background: Rectangle {
      color: renderer.prop("background", Color.popups.background)
      radius: Style.cornerRadius
      border.width: Style.normalBorderWidth
      border.color: renderer.prop("accent", Color.accent)
    }
    contentItem: ListView {
      id: suggestionList
      implicitHeight: contentHeight
      clip: true
      model: Array.isArray(nativeSearchField.suggestionModel) ? nativeSearchField.suggestionModel : []
      currentIndex: nativeSearchField.highlightedIndex
      delegate: QQC.ItemDelegate {
        required property int index
        required property var modelData
        width: suggestionList.width
        text: nativeSearchField.suggestionText(modelData)
        highlighted: index === nativeSearchField.highlightedIndex
        font.family: nativeSearchField.font.family
        font.pixelSize: nativeSearchField.font.pixelSize
        palette.text: renderer.prop("foreground", renderer.foreground)
        palette.highlightedText: Color.background
        palette.highlight: renderer.prop("accent", Color.accent)
        onHoveredChanged: {
          if (hovered && index !== nativeSearchField.highlightedIndex)
            nativeSearchField.highlightSuggestion(index)
        }
        onClicked: nativeSearchField.activateSuggestion(index)
      }
    }
  }
}
