import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "Theme"
import "Controls" as ZuiControls

Loader {
  id: root

  property var bridge: null
  property string surfaceName: ""
  property string controlId: ""
  property int renderDepth: 0
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  readonly property string iconFontFamily: Fonts.iconFamily
  readonly property string brandIconFontFamily: Fonts.brandIconFamily

  // Shared recursive delegates are framework infrastructure. Individual built-in
  // renderers consume these without duplicating ControlNode's lifecycle wiring.
  readonly property Component childDelegateComponent: childDelegate
  readonly property Component rowChildDelegateComponent: rowChildDelegate
  readonly property Component columnChildDelegateComponent: columnChildDelegate
  readonly property Component layoutChildDelegateComponent: layoutChildDelegate
  readonly property Component splitChildDelegateComponent: splitChildDelegate

  // Keep a stable snapshot per published bridge revision. A computed binding
  // that calls through bridge.nodeFor() can be re-entered by native QML while
  // several controls are resolving their adapters on iOS.
  property var node: null
  property var nativeSchema: null
  readonly property bool builtIn: nativeSchema ? nativeSchema.builtIn === true : false
  readonly property bool structuralContainer: nativeSchema ? nativeSchema.container === true : false
  property string loadedAdapterKey: ""
  property string lastComponentErrorKey: ""
  property bool adapterLoadPending: false
  readonly property int synchronousAdapterSpan: 4

  function synchronizeNode() {
    var nextNode = bridge ? bridge.nodeFor(controlId) : null
    var nextSchema = bridge && nextNode ? bridge.componentDefinition(nextNode.type) : null
    if (nativeSchema !== nextSchema) nativeSchema = nextSchema
    if (node !== nextNode) node = nextNode
  }

  function prop(name, fallback) {
    var props = node && node.props ? node.props : null
    var value = props ? props[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function hasProp(name) {
    var props = node && node.props ? node.props : null
    return props && props[name] !== undefined && props[name] !== null
  }

  function iconGlyph(name) {
    var icons = {
      ruby: "\uf3a5",
      phone: "\uf3cd",
      plus: "\uf067",
      minus: "\uf068",
      reset: "\uf2f9", refresh: "\uf2f9",
      house: "\uf015", gear: "\uf013", search: "\uf002", xmark: "\uf00d", check: "\uf00c",
      menu: "\uf0c9", user: "\uf007", bell: "\uf0f3", wifi: "\uf1eb", bluetooth: "\uf293",
      volume_high: "\uf028", volume_low: "\uf027", volume_off: "\uf026",
      play: "\uf04b", pause: "\uf04c", stop: "\uf04d", trash: "\uf1f8", edit: "\uf044",
      folder: "\uf07b", file: "\uf15b", download: "\uf019", upload: "\uf093", link: "\uf0c1",
      lock: "\uf023", unlock: "\uf09c", eye: "\uf06e", eye_slash: "\uf070",
      star: "\uf005", heart: "\uf004", info: "\uf129", warning: "\uf071",
      circle_info: "\uf05a", circle_check: "\uf058", circle_xmark: "\uf057",
      arrow_left: "\uf060", arrow_right: "\uf061", arrow_up: "\uf062", arrow_down: "\uf063",
      chevron_left: "\uf053", chevron_right: "\uf054", chevron_up: "\uf077", chevron_down: "\uf078",
      calendar: "\uf133", clock: "\uf017", camera: "\uf030", image: "\uf03e", music: "\uf001",
      terminal: "\uf120", code: "\uf121", copy: "\uf0c5", save: "\uf0c7", power: "\uf011",
      globe: "\uf0ac", location: "\uf3c5", pin: "\uf08d", android: "\uf17b", apple: "\uf179"
    }
    var key = String(name || "")
    return icons[key] || key
  }

  function iconFontFamilyFor(name) {
    var key = String(name || "")
    return ["bluetooth", "android", "apple"].indexOf(key) >= 0
      ? brandIconFontFamily : iconFontFamily
  }

  function escapeAutoText(value) {
    return String(value === undefined || value === null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
  }

  function easingType(name) {
    var easings = {
      linear: Easing.Linear,
      in_quad: Easing.InQuad, out_quad: Easing.OutQuad, in_out_quad: Easing.InOutQuad,
      in_cubic: Easing.InCubic, out_cubic: Easing.OutCubic, in_out_cubic: Easing.InOutCubic,
      in_back: Easing.InBack, out_back: Easing.OutBack, in_out_back: Easing.InOutBack,
      in_elastic: Easing.InElastic, out_elastic: Easing.OutElastic, in_out_elastic: Easing.InOutElastic,
      in_bounce: Easing.InBounce, out_bounce: Easing.OutBounce, in_out_bounce: Easing.InOutBounce
    }
    return easings[String(name || "")] === undefined ? Easing.InOutQuad : easings[String(name)]
  }

  function layoutAlignment(name, fallback) {
    var value = String(name || fallback || "center")
    if (value === "start" || value === "left" || value === "top") return Qt.AlignLeft | Qt.AlignTop
    if (value === "end" || value === "right" || value === "bottom") return Qt.AlignRight | Qt.AlignBottom
    if (value === "left_center") return Qt.AlignLeft | Qt.AlignVCenter
    if (value === "right_center") return Qt.AlignRight | Qt.AlignVCenter
    if (value === "top_center") return Qt.AlignTop | Qt.AlignHCenter
    if (value === "bottom_center") return Qt.AlignBottom | Qt.AlignHCenter
    return Qt.AlignCenter
  }

  function findRenderedItem(targetId) {
    var ancestor = root
    while (ancestor.parent) ancestor = ancestor.parent
    return findRenderedItemBelow(ancestor, String(targetId || ""))
  }

  function findRenderedItemBelow(object, targetId) {
    if (!object || targetId === "") return null
    var pending = [object]
    var visited = []
    while (pending.length > 0) {
      var current = pending.pop()
      if (!current || visited.indexOf(current) >= 0) continue
      visited.push(current)
      if (current !== root && current.controlId !== undefined && String(current.controlId) === targetId)
        return current.item || current
      var descendants = current.children || []
      for (var index = descendants.length - 1; index >= 0; index--)
        pending.push(descendants[index])
    }
    return null
  }

  function subscribed(eventName) {
    return node && Array.isArray(node.events) && node.events.indexOf(eventName) >= 0
  }

  function componentError(code, message, payload) {
    var componentType = node ? String(node.type) : "component"
    var errorCode = String(code || "component_error")
    var errorMessage = String(message || "Component failed")
    var errorKey = componentType + ":" + errorCode + ":" + errorMessage
    if (errorKey === lastComponentErrorKey) return
    lastComponentErrorKey = errorKey
    if (bridge && bridge.reportComponentError)
      bridge.reportComponentError(surfaceName, controlId, componentType, errorCode, errorMessage)
    if (!subscribed("error")) return
    var eventPayload = payload && typeof payload === "object" ? payload : ({})
    eventPayload.code = errorCode
    eventPayload.message = errorMessage
    bridge.sendEvent(surfaceName, controlId, "error", eventPayload)
  }

  function configureFace(face, childNode) {
    if (!face || !childNode) return
    if (face.hasOwnProperty("renderDepth")) face.renderDepth = renderDepth + 1
    face.bridge = bridge
    face.surfaceName = surfaceName
    face.controlId = String(childNode.id)
    face.foreground = foreground
    face.fontFamily = fontFamily
  }

  // Three adapters wanted the protocol's cursor name turned into a Qt cursor
  // shape, two of them carried their own copy of the mapping, and the third —
  // Checkbox — called `renderer.cursorShape()`, which ControlNode had never
  // defined. Every checkbox on the page threw "Property 'cursorShape' of
  // object ControlNode is not a function" and got no cursor at all. Shared
  // name-to-enum translation belongs here, beside easingType and
  // layoutAlignment, and the two private copies disagreed about which names
  // existed anyway.
  function cursorShape(name, fallback) {
    var shapes = {
      arrow: Qt.ArrowCursor,
      pointing_hand: Qt.PointingHandCursor,
      open_hand: Qt.OpenHandCursor,
      closed_hand: Qt.ClosedHandCursor,
      cross: Qt.CrossCursor,
      text: Qt.IBeamCursor,
      horizontal: Qt.SizeHorCursor,
      vertical: Qt.SizeVerCursor,
      size_all: Qt.SizeAllCursor,
      busy: Qt.BusyCursor,
      wait: Qt.WaitCursor,
      forbidden: Qt.ForbiddenCursor,
      help: Qt.WhatsThisCursor,
      blank: Qt.BlankCursor
    }
    var requested = shapes[String(name || "")]
    if (requested !== undefined) return requested
    var defaulted = shapes[String(fallback || "")]
    return defaulted === undefined ? Qt.ArrowCursor : defaulted
  }

  // Qt Quick Controls already knows the control is pressed; an adapter that
  // overrides `background` is what throws that away. The pressed appearance has
  // to be resolved locally, because waiting for Ruby to answer the click is the
  // whole of the delay the user feels -- Ruby turns a sidebar activation into a
  // complete set of page patches in 3-12 ms, and the client then spends 85 ms
  // to several seconds building the new page before anything repaints.
  //
  // These two resolve it in one place: the protocol's `pressed_background` and
  // `pressed_foreground` when an application declares them, otherwise a value
  // derived from what the control is already painting. Only the fill is
  // derived. A tinted or darkened fill keeps the resting label legible, so
  // `pressed_foreground` is what moves the label as well.
  function pressedBackground(resting) {
    return prop("pressed_background", Style.pressedFillFor(
      resolvedColor(resting, Qt.rgba(0, 0, 0, 0)),
      resolvedColor(prop("accent", ""), Color.accent)))
  }

  function pressedForeground(resting) {
    return prop("pressed_foreground", resting)
  }

  // A protocol colour arrives as a string and an adapter's resting colour may
  // be either, so the shared derivation above takes neither on trust. Qt.color
  // throws on anything it cannot read, including the empty string.
  function resolvedColor(value, fallback) {
    try {
      return Qt.color(value)
    } catch (error) {
      return fallback
    }
  }

  function borderImageTileMode(value) {
    var mode = String(value || "stretch")
    if (mode === "repeat") return BorderImage.Repeat
    if (mode === "round") return BorderImage.Round
    return BorderImage.Stretch
  }

  // The renderer resolves a relative asset path against the directory holding
  // the application's main.rb, because that is the only directory the author
  // of the application knows about. Anything that skips this and hands a
  // relative path straight to QML resolves it against the adapter's own
  // directory inside the framework checkout instead, and asks for a file that
  // was never there — "demos/nova_pour/assets/future-pour-bar.webp" became
  // "<framework>/Components/Builtins/demos/nova_pour/assets/future-pour-bar.webp".
  //
  // Two further corrections over what this used to return. A bare absolute
  // path left it as a URL with no scheme, which QML resolved against the
  // adapter's base URL and happened to come out right on Unix; and a single
  // letter followed by a colon was taken for a URL scheme, so every Windows
  // path "C:/..." was passed through as a "c:" URL.
  function assetUrl(value) {
    var source = String(value || "").replace(/\\/g, "/")
    if (source === "") return ""
    if (windowsPath(source)) return fileUrl(source)
    if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(source)) return source
    if (source.charAt(0) === "/") return fileUrl(source)
    var project = bridge && bridge.projectDir ? String(bridge.projectDir) : ""
    return project === "" ? Qt.resolvedUrl(source) : fileUrl(project + "/" + source)
  }

  function windowsPath(value) {
    return /^[a-zA-Z]:\//.test(String(value))
  }

  function fileUrl(value) {
    var path = String(value).replace(/\\/g, "/")
    if (path.charAt(0) !== "/") path = "/" + path
    return "file://" + encodeURI(path).replace(/#/g, "%23").replace(/\?/g, "%3F")
  }

  function builtInSource(typeName) {
    var parts = String(typeName || "").split("_")
    for (var index = 0; index < parts.length; index++)
      parts[index] = parts[index].charAt(0).toUpperCase() + parts[index].slice(1)
    return Qt.resolvedUrl("Components/Builtins/" + parts.join("") + ".qml")
  }

  function ensureAdapterLoaded() {
    adapterLoadPending = false
    if (!node || adapterSource === "") {
      loadedAdapterKey = ""
      if (source !== "") source = ""
      return
    }
    var adapterKey = String(node.type) + ":" + String(adapterSource)
    if (loadedAdapterKey === adapterKey && item) return
    loadedAdapterKey = adapterKey
    if (builtIn) setSource(adapterSource, { renderer: root })
    else source = adapterSource
  }

  // A deferred adapter load has to be owned by the node it loads. A bare
  // Qt.callLater closure outlives the node: when a page is replaced, every
  // scheduled callback for the nodes that went away still runs, fails with
  // "attempted to evaluate a function in an invalid context", and leaves
  // adapterLoadPending stuck true on any node the renderer reuses. That node
  // then refuses every later load request and renders as nothing at all — a
  // card silently missing from a page it had rendered a moment earlier.
  // A Timer is a child of the node, so it is cancelled when the node goes.
  Timer {
    id: adapterLoadTimer
    interval: 0
    repeat: false
    onTriggered: {
      root.adapterLoadPending = false
      root.ensureAdapterLoaded()
    }
  }

  Timer {
    id: transitionTimer
    interval: 0
    repeat: false
    onTriggered: root.runTransition()
  }

  function scheduleAdapterLoad() {
    if (adapterLoadPending) return
    adapterLoadPending = true
    adapterLoadTimer.restart()
  }

  function requestAdapterLoad() {
    // Break recursive QML construction only at bounded depth intervals.
    // This protects Qt's iOS stack without delaying every individual node.
    if (renderDepth > 0 && renderDepth % synchronousAdapterSpan !== 0) {
      ensureAdapterLoaded()
      return
    }
    root.scheduleAdapterLoad()
  }

  function nativeDefinition() {
    return nativeSchema
  }

  function optionValue(option) {
    return option !== null && typeof option === "object" && option.value !== undefined ? option.value : option
  }

  function optionLabel(option) {
    return option !== null && typeof option === "object" && option.label !== undefined ? option.label : optionValue(option)
  }

  function syncNativeProperties() {
    var definition = nativeDefinition()
    if (!item || !definition || !definition.autoBind) return
    var props = node && node.props ? node.props : ({})
    var common = { visible: true, enabled: true, opacity: true, scale: true, rotation: true, z: true, width: true, height: true }
    for (var protocolName in props) {
      if (common[protocolName]) continue
      var qmlName = definition.propertyMap[protocolName] || protocolName
      if (item.hasOwnProperty(qmlName)) item[qmlName] = props[protocolName]
    }
  }

  function nativeEventPayload(args) {
    if (args.length === 0) return ({})
    if (args.length === 1 && args[0] !== null && typeof args[0] === "object" && !Array.isArray(args[0])) return args[0]
    var values = []
    for (var i = 0; i < args.length; i++) {
      var value = args[i]
      if (value === null || typeof value === "string" || typeof value === "number" || typeof value === "boolean"
          || Array.isArray(value)) values.push(value)
      else values.push(String(value))
    }
    return values.length === 1 ? { value: values[0] } : { arguments: values }
  }

  function connectNativeEvents() {
    var definition = nativeDefinition()
    if (!item || !definition || !definition.autoBind || !node || !Array.isArray(node.events)) return
    for (let i = 0; i < node.events.length; i++) {
      let protocolName = String(node.events[i])
      if (protocolName === "mount" || protocolName === "unmount") continue
      let qmlName = definition.eventMap[protocolName] || protocolName
      let signal = item[qmlName]
      if (signal && typeof signal.connect === "function") {
        signal.connect(function() {
          root.bridge.sendEvent(root.surfaceName, root.controlId, protocolName, root.nativeEventPayload(arguments))
        })
      }
    }
  }

  function runTransition() {
    var transitions = node && Array.isArray(node.transitions)
      ? node.transitions
      : (node && node.transition ? [node.transition] : [])
    if (!item || transitions.length === 0) return
    for (var transitionIndex = 0; transitionIndex < transitions.length; transitionIndex++)
      runTrack(transitions[transitionIndex])
  }

  function runTrack(transition) {
    var commonProperties = ["opacity", "scale", "rotation", "z", "width", "height"]
    var definition = nativeDefinition()
    var animationProperty = definition && definition.propertyMap[transition.property]
      ? definition.propertyMap[transition.property] : transition.property
    var animationTarget = commonProperties.indexOf(transition.property) >= 0 ? root : item
    if (!animationTarget.hasOwnProperty(animationProperty)) return
    if (transition.from === undefined || transition.from === null) return
    var animation = propertyAnimationFactory.createObject(root, {
      target: animationTarget,
      property: String(animationProperty),
      from: transition.from,
      to: transition.to,
      duration: Number(transition.duration)
    })
    animation.easing.type = easingType(transition.easing)
    var delay = Number(transition.delay || 0)
    if (delay > 0) delayedAnimationFactory.createObject(root, { interval: delay, animation: animation }).start()
    else animation.start()
  }

  visible: node !== null && prop("visible", true) !== false
  enabled: prop("enabled", true) !== false
  opacity: Number(prop("opacity", 1))
  scale: Number(prop("scale", 1))
  rotation: Number(prop("rotation", 0))
  z: Number(prop("z", 0))
  sourceComponent: null
  source: ""
  readonly property string adapterSource: !node || !nativeSchema ? ""
    : (builtIn ? builtInSource(node.type) : bridge.componentSource(node.type))
  onAdapterSourceChanged: requestAdapterLoad()
  onBridgeChanged: synchronizeNode()
  onControlIdChanged: synchronizeNode()
  onLoaded: {
    lastComponentErrorKey = ""
    if (!item) return
    if (builtIn && item.hasOwnProperty("renderer")) {
      item.renderer = root
    } else if (!builtIn) {
      if (item.hasOwnProperty("bridge")) item.bridge = bridge
      if (item.hasOwnProperty("surfaceName")) item.surfaceName = surfaceName
      if (item.hasOwnProperty("controlId")) item.controlId = controlId
      if (item.hasOwnProperty("node")) item.node = node
      syncNativeProperties()
      connectNativeEvents()
    }
    runTransition()
    if (subscribed("mount")) bridge.sendEvent(surfaceName, controlId, "mount", {})
  }
  onStatusChanged: {
    if (status === Loader.Error)
      componentError("component_load_failed", "Unable to load the declared " + (node ? node.type : "component") + " renderer", { source: String(source) })
  }
  onNodeChanged: {
    if (item && !builtIn && item.hasOwnProperty("node")) item.node = node
    if (!builtIn) syncNativeProperties()
    transitionTimer.restart()
  }
  Component.onCompleted: {
    root.synchronizeNode()
    root.requestAdapterLoad()
  }

  Connections {
    target: root.bridge
    function onRevisionChanged() { root.synchronizeNode() }
  }

  TapHandler {
    enabled: root.structuralContainer && root.subscribed("click")
    onTapped: root.bridge.sendEvent(root.surfaceName, root.controlId, "click", {})
  }

  Repeater {
    id: nativeChildren
    parent: root.item && root.item.hasOwnProperty("contentHost") && root.item.contentHost
      ? root.item.contentHost
      : root
    model: !root.builtIn && root.node && root.nativeDefinition() && root.nativeDefinition().container
      && Array.isArray(root.node.children) ? root.node.children : []
    delegate: childDelegate
  }

  Component {
    id: propertyAnimationFactory
    PropertyAnimation { onStopped: destroy() }
  }

  Component {
    id: delayedAnimationFactory
    Timer {
      required property var animation
      repeat: false
      onTriggered: { animation.start(); destroy() }
    }
  }

  Component.onDestruction: {
    if (bridge && subscribed("unmount")) bridge.sendEvent(surfaceName, controlId, "unmount", {})
  }

  Component {
    id: splitChildDelegate
    Loader {
      required property var modelData
      QQC.SplitView.minimumWidth: Number(modelData.props && modelData.props.minimum_width !== undefined ? modelData.props.minimum_width : 0)
      QQC.SplitView.minimumHeight: Number(modelData.props && modelData.props.minimum_height !== undefined ? modelData.props.minimum_height : 0)
      QQC.SplitView.preferredWidth: Number(modelData.props && modelData.props.preferred_width !== undefined ? modelData.props.preferred_width : implicitWidth)
      QQC.SplitView.preferredHeight: Number(modelData.props && modelData.props.preferred_height !== undefined ? modelData.props.preferred_height : implicitHeight)
      QQC.SplitView.fillWidth: modelData.props && modelData.props.fill_width === true
      QQC.SplitView.fillHeight: modelData.props && modelData.props.fill_height === true
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.renderDepth = root.renderDepth + 1
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

  Component {
    id: childDelegate
    Loader {
      required property var modelData
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.renderDepth = root.renderDepth + 1
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

  Component {
    id: rowChildDelegate
    Loader {
      required property var modelData
      readonly property string crossAlignment: String(root.prop("alignment", "center"))
      anchors.top: crossAlignment === "start" || crossAlignment === "top" ? parent.top : undefined
      anchors.verticalCenter: crossAlignment === "center" ? parent.verticalCenter : undefined
      anchors.bottom: crossAlignment === "end" || crossAlignment === "bottom" ? parent.bottom : undefined
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.renderDepth = root.renderDepth + 1
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

  Component {
    id: layoutChildDelegate
    Loader {
      required property var modelData
      readonly property var layoutProps: modelData && modelData.props ? modelData.props : ({})
      Layout.fillWidth: layoutProps.fill_width === true
      Layout.fillHeight: layoutProps.fill_height === true
      Layout.preferredWidth: layoutProps.preferred_width === undefined ? -1 : Number(layoutProps.preferred_width)
      Layout.preferredHeight: layoutProps.preferred_height === undefined ? -1 : Number(layoutProps.preferred_height)
      Layout.minimumWidth: layoutProps.minimum_width === undefined ? 0 : Number(layoutProps.minimum_width)
      Layout.minimumHeight: layoutProps.minimum_height === undefined ? 0 : Number(layoutProps.minimum_height)
      Layout.maximumWidth: layoutProps.maximum_width === undefined ? Infinity : Number(layoutProps.maximum_width)
      Layout.maximumHeight: layoutProps.maximum_height === undefined ? Infinity : Number(layoutProps.maximum_height)
      Layout.alignment: root.layoutAlignment(layoutProps.layout_alignment, root.prop("alignment", "center"))
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.renderDepth = root.renderDepth + 1
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

  Component {
    id: columnChildDelegate
    Loader {
      required property var modelData
      readonly property string crossAlignment: String(root.prop("alignment", "start"))
      anchors.left: crossAlignment === "start" || crossAlignment === "left" ? parent.left : undefined
      anchors.horizontalCenter: crossAlignment === "center" ? parent.horizontalCenter : undefined
      anchors.right: crossAlignment === "end" || crossAlignment === "right" ? parent.right : undefined
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.renderDepth = root.renderDepth + 1
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

}
