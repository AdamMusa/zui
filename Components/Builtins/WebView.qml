import QtQuick
import QtWebEngine

WebEngineView {
  id: webRoot
  property var renderer: null
  property int handledCommandRevision: -1
  implicitWidth: Number(renderer ? renderer.prop("width", 800) : 800)
  implicitHeight: Number(renderer ? renderer.prop("height", 600) : 600)
  url: renderer ? renderer.assetUrl(renderer.prop("url", "about:blank")) : "about:blank"
  zoomFactor: Number(renderer ? renderer.prop("zoom_factor", 1) : 1)
  backgroundColor: renderer ? renderer.prop("background_color", "white") : "white"
  activeFocusOnPress: !renderer || renderer.prop("active_focus_on_press", true) !== false
  settings.javascriptEnabled: !renderer || renderer.prop("javascript_enabled", true) !== false
  settings.localStorageEnabled: !renderer || renderer.prop("local_storage_enabled", true) !== false
  settings.autoLoadImages: !renderer || renderer.prop("auto_load_images", true) !== false
  settings.fullScreenSupportEnabled: renderer && renderer.prop("full_screen_support", false) === true

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  function handleCommand() {
    if (!renderer) return
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    handledCommandRevision = revision
    var command = String(renderer.prop("command", ""))
    if (command === "back" && canGoBack) goBack()
    else if (command === "forward" && canGoForward) goForward()
    else if (command === "reload") reload()
    else if (command === "stop") stop()
  }
  function loadHtmlIfNeeded() {
    if (!renderer) return
    var markup = String(renderer.prop("html", ""))
    if (markup !== "") loadHtml(markup, String(renderer.prop("base_url", "")))
  }

  onLoadingChanged: function(request) {
    if (request.status === WebEngineLoadingInfo.LoadStartedStatus) send("load_start", { url: String(request.url) })
    else if (request.status === WebEngineLoadingInfo.LoadSucceededStatus) send("load_success", { url: String(request.url) })
    else if (request.status === WebEngineLoadingInfo.LoadFailedStatus) {
      var payload = { url: String(request.url), native_code: request.errorCode }
      if (renderer) renderer.componentError("web_load_failed", request.errorString, payload)
      send("load_failure", { url: String(request.url), code: request.errorCode, message: request.errorString })
    }
  }
  onLoadProgressChanged: send("load_progress", { value: loadProgress })
  onUrlChanged: send("url_change", { value: String(url), can_go_back: canGoBack, can_go_forward: canGoForward })
  onTitleChanged: send("title_change", { value: title })
  onNavigationRequested: function(request) { send("navigation", { url: String(request.url), navigation_type: request.navigationType, main_frame: request.isMainFrame }) }
  onFullScreenRequested: function(request) { send("full_screen", { value: request.toggleOn }); request.accept() }
  onPermissionRequested: function(permission) { send("permission", { origin: String(permission.origin), type: permission.permissionType }) }
  onNewWindowRequested: function(request) { send("new_window", { url: String(request.requestedUrl), disposition: request.destination }) }
  Component.onCompleted: { loadHtmlIfNeeded(); handleCommand() }
  Connections { target: renderer; function onNodeChanged() { webRoot.loadHtmlIfNeeded(); webRoot.handleCommand() } }
}
