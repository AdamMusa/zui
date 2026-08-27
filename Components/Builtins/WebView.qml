import QtQuick
import QtWebView

WebView {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  function statusName(value) {
    return ["started", "stopped", "succeeded", "failed"][Number(value)] || "unknown"
  }
  function synchronizeSettings() {
    var props = renderer && renderer.node && renderer.node.props ? renderer.node.props : null
    if (!props) return
    // Qt's Darwin WebView creates its native settings object during component
    // completion. Eager bindings can call into it while its WKWebView is still
    // null, so preserve platform defaults and defer only explicit overrides.
    if (Qt.platform.os === "ios") {
      var changesPlatformDefaults = props.local_storage === false || props.javascript === false
        || props.allow_file_access === true || props.local_content_file_access === true
      if (changesPlatformDefaults)
        renderer.componentError("web_view_settings_unsupported",
          "Qt 6.8 cannot safely override native WebView settings on iOS", {})
      return
    }
    if (props.local_storage !== undefined) settings.localStorageEnabled = props.local_storage !== false
    if (props.javascript !== undefined) settings.javaScriptEnabled = props.javascript !== false
    if (props.allow_file_access !== undefined) settings.allowFileAccess = props.allow_file_access === true
    if (props.local_content_file_access !== undefined)
      settings.localContentCanAccessFileUrls = props.local_content_file_access === true
  }
  function synchronize() {
    synchronizeSettings()
    processCommand()
  }
  function scheduleSynchronize() { Qt.callLater(synchronize) }
  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    var html = String(renderer.prop("html", ""))
    if (first && html !== "") loadHtml(html, String(renderer.prop("base_url", "")))
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", ""))
    if (command === "back") goBack()
    else if (command === "forward") goForward()
    else if (command === "reload") reload()
    else if (command === "stop") stop()
    else if (command === "load_html") loadHtml(html, String(renderer.prop("base_url", "")))
    else if (command === "javascript") runJavaScript(String(renderer.prop("script", "")), function(result) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "javascript", { result: result })
    })
    else if (command === "set_cookie") setCookie(String(renderer.prop("cookie_domain", "")), String(renderer.prop("cookie_name", "")), String(renderer.prop("cookie_value", "")))
    else if (command === "delete_cookie") deleteCookie(String(renderer.prop("cookie_domain", "")), String(renderer.prop("cookie_name", "")))
    else if (command === "delete_all_cookies") deleteAllCookies()
  }
  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 420))
  visible: renderer.prop("visible", true) !== false
  url: String(renderer.prop("url", ""))
  httpUserAgent: String(renderer.prop("http_user_agent", ""))
  onLoadingChanged: function(request) {
    var name = statusName(request.status)
    var payload = { status: name, native_status: Number(request.status), url: String(request.url),
      error: String(request.errorString), can_go_back: canGoBack, can_go_forward: canGoForward }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "load", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "navigation", { can_go_back: canGoBack, can_go_forward: canGoForward })
    if (name === "failed") renderer.componentError("web_view_load_failed", request.errorString, payload)
  }
  onLoadProgressChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "progress", { value: loadProgress })
  onTitleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "title", { value: title })
  onUrlChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "url_change", { value: String(url) })
  onCookieAdded: function(domain, name) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cookie", { action: "added", domain: domain, name: name }) }
  onCookieRemoved: function(domain, name) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cookie", { action: "removed", domain: domain, name: name }) }
  Component.onCompleted: scheduleSynchronize()
  Connections { target: renderer; function onNodeChanged() { root.scheduleSynchronize() } }
}
