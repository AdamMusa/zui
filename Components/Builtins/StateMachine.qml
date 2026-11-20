import QtQuick
import QtQml.StateMachine as Machine

// QtQml.StateMachine is the full hierarchical machine: nested states, history,
// parallel regions and timed transitions. It is a different system from
// QtQuick's State/StateGroup, which Zui exposes as state and state_group.
//
// The machine is assembled from the declared child nodes rather than from
// nested QML, because a state is a QObject while every rendered Zui node is an
// Item. Child adapters only describe themselves; this adapter owns the real
// hierarchy and addresses each state's events back to that state's own node.
Item {
  id: machineRoot

  required property var renderer

  readonly property var stateTypes: ["machine_state", "final_state", "history_state"]
  readonly property var transitionTypes: ["signal_transition", "timeout_transition"]

  property string handledStructureKey: ""
  property int handledEventRevision: -1
  property var statesByName: ({})
  property var busesByEvent: ({})
  property var rootNatives: []
  property var stateEntries: []

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function childModeValue(value) {
    return String(value) === "parallel" ? Machine.State.ParallelStates
                                        : Machine.State.ExclusiveStates
  }

  function historyTypeValue(value) {
    return String(value) === "deep" ? Machine.HistoryState.DeepHistory
                                    : Machine.HistoryState.ShallowHistory
  }

  function restorePolicyValue() {
    return String(renderer.prop("restore_policy", "none")) === "properties"
      ? Machine.QState.RestoreProperties : Machine.QState.DontRestoreProperties
  }

  function nodeName(node) {
    var props = node.props || {}
    return String(props.name === undefined || props.name === null ? node.id : props.name)
  }

  function childrenOfType(node, types) {
    var children = node && Array.isArray(node.children) ? node.children : []
    var result = []
    for (var index = 0; index < children.length; index++) {
      if (types.indexOf(String(children[index].type)) >= 0) result.push(children[index])
    }
    return result
  }

  function structureOf(node) {
    var children = node && Array.isArray(node.children) ? node.children : []
    var result = []
    for (var index = 0; index < children.length; index++) {
      var child = children[index]
      var type = String(child.type)
      if (stateTypes.indexOf(type) < 0 && transitionTypes.indexOf(type) < 0) continue
      result.push({ type: type, id: String(child.id), props: child.props || {},
                    children: structureOf(child) })
    }
    return result
  }

  function structureKey() {
    return JSON.stringify({
      states: structureOf(renderer.node),
      initial: String(renderer.prop("initial", "")),
      child_mode: String(renderer.prop("child_mode", "exclusive")),
      restore_policy: String(renderer.prop("restore_policy", "none"))
    })
  }

  function busFor(eventName) {
    if (!busesByEvent[eventName]) busesByEvent[eventName] = busFactory.createObject(machineRoot, {})
    return busesByEvent[eventName]
  }

  function publishToNode(node, eventName, payload) {
    var events = Array.isArray(node.events) ? node.events : []
    if (events.indexOf(eventName) < 0) return
    renderer.bridge.sendEvent(renderer.surfaceName, String(node.id), eventName, payload)
  }

  function activeStateNames() {
    var names = []
    for (var index = 0; index < stateEntries.length; index++) {
      var entry = stateEntries[index]
      if (entry.nativeState && entry.nativeState.active) names.push(entry.name)
    }
    return names
  }

  function publishChange(reason, name) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      reason: reason, name: name, active: activeStateNames(), running: nativeMachine.running
    })
  }

  // A state's active flag settles after its entered signal, and one Ruby
  // event may move the machine through several states. Deferring coalesces
  // those into a single change carrying the configuration that settled.
  function scheduleChange(reason, name) {
    Qt.callLater(publishChange, reason, name)
  }

  function connectState(nativeState, node, name) {
    nativeState.entered.connect(function() {
      publishToNode(node, "enter", { name: name })
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "enter", { name: name })
      scheduleChange("enter", name)
    })
    nativeState.exited.connect(function() {
      publishToNode(node, "exit", { name: name })
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "exit", { name: name })
    })
    if (String(node.type) !== "machine_state") return
    nativeState.finished.connect(function() { publishToNode(node, "finish", { name: name }) })
  }

  function createStates(parentNative, node) {
    var nodes = childrenOfType(node, stateTypes)
    for (var index = 0; index < nodes.length; index++) {
      var child = nodes[index]
      var props = child.props || {}
      var name = nodeName(child)
      var type = String(child.type)
      var nativeState = null

      if (type === "final_state") {
        nativeState = finalStateFactory.createObject(parentNative, { objectName: name })
      } else if (type === "history_state") {
        nativeState = historyStateFactory.createObject(parentNative, {
          objectName: name, historyType: historyTypeValue(props.history_type)
        })
      } else {
        nativeState = stateFactory.createObject(parentNative, {
          objectName: name, childMode: childModeValue(props.child_mode)
        })
      }
      if (!nativeState) continue

      if (parentNative === nativeMachine) rootNatives.push(nativeState)
      statesByName[name] = nativeState
      stateEntries.push({ name: name, node: child, nativeState: nativeState, type: type })
      connectState(nativeState, child, name)
      if (type === "machine_state") createStates(nativeState, child)
    }
  }

  function createTransitions(parentNative, node) {
    var nodes = childrenOfType(node, transitionTypes)
    for (var index = 0; index < nodes.length; index++) {
      var child = nodes[index]
      var props = child.props || {}
      var targetName = String(props.target === undefined || props.target === null
        ? "" : props.target)
      var target = statesByName[targetName]
      if (!target) {
        renderer.componentError("state_machine_unknown_target",
          "No state named " + targetName + " for a " + String(child.type),
          { target: targetName, transition: String(child.id) })
        continue
      }

      var nativeState = null
      if (String(child.type) === "timeout_transition") {
        var timeout = Math.max(0, Math.floor(Number(props.timeout === undefined ? 0 : props.timeout)))
        nativeState = timeoutTransitionFactory.createObject(parentNative, {
          timeout: timeout, targetState: target
        })
      } else {
        var eventName = String(props.on === undefined || props.on === null ? "" : props.on)
        if (eventName === "") {
          renderer.componentError("signal_transition_without_event",
            "A signal_transition needs the name of the event it listens for",
            { transition: String(child.id) })
          continue
        }
        nativeState = signalTransitionFactory.createObject(parentNative, {
          signal: busFor(eventName).fired, targetState: target
        })
      }
      if (nativeState) connectTransition(nativeState, child, targetName)
    }
  }

  function connectTransition(nativeState, node, targetName) {
    nativeState.triggered.connect(function() {
      publishToNode(node, "trigger", { target: targetName })
    })
  }

  function applyHistoryDefaults() {
    for (var index = 0; index < stateEntries.length; index++) {
      var entry = stateEntries[index]
      if (entry.type !== "history_state") continue
      var requested = String((entry.node.props || {}).default_state === undefined
        ? "" : (entry.node.props || {}).default_state)
      if (requested === "") continue
      var target = statesByName[requested]
      if (target) entry.nativeState.defaultState = target
      else renderer.componentError("history_state_unknown_default",
        "No state named " + requested + " for a history_state default",
        { state: entry.name, default_state: requested })
    }
  }

  function assignInitial(parentNative, node) {
    var nodes = childrenOfType(node, stateTypes)
    if (nodes.length === 0) return
    var requested = String((node.props || {}).initial === undefined
      || (node.props || {}).initial === null ? "" : (node.props || {}).initial)
    var chosen = ""
    for (var index = 0; index < nodes.length; index++) {
      var props = nodes[index].props || {}
      var name = nodeName(nodes[index])
      if (requested !== "" && name === requested) { chosen = name; break }
      if (requested === "" && props.initial === true) { chosen = name; break }
    }
    if (chosen === "") chosen = nodeName(nodes[0])
    if (statesByName[chosen]) parentNative.initialState = statesByName[chosen]
  }

  function applyInitialStates() {
    assignInitial(nativeMachine, renderer.node)
    for (var index = 0; index < stateEntries.length; index++) {
      var entry = stateEntries[index]
      if (entry.type !== "machine_state") continue
      assignInitial(entry.nativeState, entry.node)
    }
  }

  function teardown() {
    nativeMachine.running = false
    nativeMachine.initialState = bootState
    for (var index = rootNatives.length - 1; index >= 0; index--) {
      if (rootNatives[index]) rootNatives[index].destroy()
    }
    rootNatives = []
    statesByName = ({})
    stateEntries = []
  }

  function rebuild() {
    teardown()
    createStates(nativeMachine, renderer.node)
    if (stateEntries.length === 0) {
      renderer.componentError("state_machine_without_states",
        "A state_machine needs at least one machine_state, final_state or history_state", {})
      return
    }
    createTransitions(nativeMachine, renderer.node)
    for (var index = 0; index < stateEntries.length; index++) {
      var entry = stateEntries[index]
      if (entry.type === "machine_state") createTransitions(entry.nativeState, entry.node)
    }
    applyHistoryDefaults()
    applyInitialStates()
  }

  function applyRunning() {
    var shouldRun = renderer.prop("running", false) === true
    if (stateEntries.length === 0) return
    if (nativeMachine.running !== shouldRun) nativeMachine.running = shouldRun
  }

  // Ruby fires an event by naming it and bumping event_revision, so the same
  // event can be sent twice without the machine confusing it for one.
  function fireEvent() {
    var revision = Number(renderer.prop("event_revision", 0))
    if (revision === handledEventRevision) return
    handledEventRevision = revision
    var name = String(renderer.prop("event", ""))
    if (name === "") return
    if (!busesByEvent[name]) {
      renderer.componentError("state_machine_unknown_event",
        "No signal_transition listens for event " + name, { event: name })
      return
    }
    busesByEvent[name].fired()
  }

  function synchronize() {
    var key = structureKey()
    if (key !== handledStructureKey) {
      handledStructureKey = key
      rebuild()
    }
    applyRunning()
    fireEvent()
  }

  Component { id: stateFactory; Machine.State {} }
  Component { id: finalStateFactory; Machine.FinalState {} }
  Component { id: historyStateFactory; Machine.HistoryState {} }
  Component { id: signalTransitionFactory; Machine.SignalTransition {} }
  Component { id: timeoutTransitionFactory; Machine.TimeoutTransition {} }
  Component { id: busFactory; QtObject { signal fired() } }

  Machine.StateMachine {
    id: nativeMachine
    childMode: machineRoot.childModeValue(renderer.prop("child_mode", "exclusive"))
    globalRestorePolicy: machineRoot.restorePolicyValue()
    // A declared placeholder keeps Qt from warning about a machine with no
    // initial state while the real states are still being assembled.
    initialState: bootState

    Machine.State { id: bootState }

    onStarted: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "start",
        { active: machineRoot.activeStateNames() })
      machineRoot.scheduleChange("start", "")
    }
    onStopped: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "stop", {})
      machineRoot.scheduleChange("stop", "")
    }
    onFinished: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "finish", {})
      machineRoot.scheduleChange("finish", "")
    }
  }

  Component.onCompleted: synchronize()
  Component.onDestruction: teardown()
  Connections { target: renderer; function onNodeChanged() { machineRoot.synchronize() } }
}
