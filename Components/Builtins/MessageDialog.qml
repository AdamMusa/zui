import QtQuick
import QtQuick.Dialogs as Dialogs

Dialogs.MessageDialog {
  id: messageDialogRoot

  required property var renderer
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false

  function buttonsValue(value) {
    var names = Array.isArray(value) ? value : (value === null || value === undefined ? [] : [value])
    var result = Dialogs.MessageDialog.NoButton
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "ok") result |= Dialogs.MessageDialog.Ok
      else if (name === "save") result |= Dialogs.MessageDialog.Save
      else if (name === "save_all") result |= Dialogs.MessageDialog.SaveAll
      else if (name === "open") result |= Dialogs.MessageDialog.Open
      else if (name === "yes") result |= Dialogs.MessageDialog.Yes
      else if (name === "yes_to_all") result |= Dialogs.MessageDialog.YesToAll
      else if (name === "no") result |= Dialogs.MessageDialog.No
      else if (name === "no_to_all") result |= Dialogs.MessageDialog.NoToAll
      else if (name === "abort") result |= Dialogs.MessageDialog.Abort
      else if (name === "retry") result |= Dialogs.MessageDialog.Retry
      else if (name === "ignore") result |= Dialogs.MessageDialog.Ignore
      else if (name === "close") result |= Dialogs.MessageDialog.Close
      else if (name === "cancel") result |= Dialogs.MessageDialog.Cancel
      else if (name === "discard") result |= Dialogs.MessageDialog.Discard
      else if (name === "help") result |= Dialogs.MessageDialog.Help
      else if (name === "apply") result |= Dialogs.MessageDialog.Apply
      else if (name === "reset") result |= Dialogs.MessageDialog.Reset
      else if (name === "restore_defaults") result |= Dialogs.MessageDialog.RestoreDefaults
    }
    return result
  }

  function buttonName(button) {
    if (button === Dialogs.MessageDialog.Ok) return "ok"
    if (button === Dialogs.MessageDialog.Save) return "save"
    if (button === Dialogs.MessageDialog.SaveAll) return "save_all"
    if (button === Dialogs.MessageDialog.Open) return "open"
    if (button === Dialogs.MessageDialog.Yes) return "yes"
    if (button === Dialogs.MessageDialog.YesToAll) return "yes_to_all"
    if (button === Dialogs.MessageDialog.No) return "no"
    if (button === Dialogs.MessageDialog.NoToAll) return "no_to_all"
    if (button === Dialogs.MessageDialog.Abort) return "abort"
    if (button === Dialogs.MessageDialog.Retry) return "retry"
    if (button === Dialogs.MessageDialog.Ignore) return "ignore"
    if (button === Dialogs.MessageDialog.Close) return "close"
    if (button === Dialogs.MessageDialog.Cancel) return "cancel"
    if (button === Dialogs.MessageDialog.Discard) return "discard"
    if (button === Dialogs.MessageDialog.Help) return "help"
    if (button === Dialogs.MessageDialog.Apply) return "apply"
    if (button === Dialogs.MessageDialog.Reset) return "reset"
    if (button === Dialogs.MessageDialog.RestoreDefaults) return "restore_defaults"
    return "unknown"
  }

  function roleName(role) {
    if (role === Dialogs.MessageDialog.AcceptRole) return "accept"
    if (role === Dialogs.MessageDialog.RejectRole) return "reject"
    if (role === Dialogs.MessageDialog.DestructiveRole) return "destructive"
    if (role === Dialogs.MessageDialog.ActionRole) return "action"
    if (role === Dialogs.MessageDialog.HelpRole) return "help"
    if (role === Dialogs.MessageDialog.YesRole) return "yes"
    if (role === Dialogs.MessageDialog.NoRole) return "no"
    if (role === Dialogs.MessageDialog.ApplyRole) return "apply"
    if (role === Dialogs.MessageDialog.ResetRole) return "reset"
    return "invalid"
  }

  function modalityValue(value) {
    var name = String(value || "application")
    if (name === "none" || name === "non_modal") return Qt.NonModal
    if (name === "window" || name === "window_modal") return Qt.WindowModal
    return Qt.ApplicationModal
  }

  function syncOpenState() {
    if (requestedOpen === visible) return
    if (requestedOpen) open()
    else close()
  }

  title: String(renderer.prop("title", ""))
  text: String(renderer.prop("message", ""))
  informativeText: String(renderer.prop("informative_text", ""))
  detailedText: String(renderer.prop("detailed_text", ""))
  buttons: buttonsValue(renderer.prop("buttons", ["ok"]))
  modality: modalityValue(renderer.prop("modality", "application"))

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
  onButtonClicked: function(button, role) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "button", {
      button: buttonName(button), role: roleName(role)
    })
  }
  onAccepted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", {})
  onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {})
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "open" : "close", {})
}
