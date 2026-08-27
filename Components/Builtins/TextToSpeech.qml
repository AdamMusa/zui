import QtQuick
import QtTextToSpeech

Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  property bool nativeRequested: false
  property bool simulatorErrorReported: false
  property string pendingCommand: ""
  visible: false
  function genderValue() {
    var value = String(renderer.prop("voice_gender", "unknown"))
    if (value === "male") return Voice.Male
    if (value === "female") return Voice.Female
    return Voice.Unknown
  }
  function ageValue() {
    var value = String(renderer.prop("voice_age", "other"))
    if (value === "child") return Voice.Child
    if (value === "teenager") return Voice.Teenager
    if (value === "adult") return Voice.Adult
    if (value === "senior") return Voice.Senior
    return Voice.Other
  }
  function stateName(value) {
    return ["ready", "speaking", "paused", "error", "synthesizing"][Number(value)] || "unknown"
  }
  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    var command = String(renderer.prop("command", ""))
    var text = String(renderer.prop("text", ""))
    if (first && renderer.prop("auto_speak", false) === true && text !== "") command = "say"
    else if (first && revision <= 0) return
    if (["say", "enqueue", "stop", "pause", "resume"].indexOf(command) < 0) return
    if (zuiIosSimulator) {
      if (!simulatorErrorReported) {
        simulatorErrorReported = true
        renderer.componentError("text_to_speech_simulator_unavailable",
          "Native text-to-speech is unavailable in this iOS Simulator runtime", {})
      }
      return
    }
    pendingCommand = command
    nativeRequested = true
    runPendingCommand()
  }

  function runPendingCommand() {
    var nativeSpeech = speechLoader.item
    if (!nativeSpeech || pendingCommand === "") return
    var command = pendingCommand
    pendingCommand = ""
    var text = String(renderer.prop("text", ""))
    if (command === "say") nativeSpeech.say(text)
    else if (command === "enqueue") nativeSpeech.enqueue(text)
    else if (command === "stop") nativeSpeech.stop()
    else if (command === "pause") nativeSpeech.pause()
    else if (command === "resume") nativeSpeech.resume()
  }

  Loader {
    id: speechLoader
    active: root.nativeRequested && !zuiIosSimulator
    asynchronous: true
    sourceComponent: Component {
      TextToSpeech {
        id: nativeSpeech
        engine: String(root.renderer.prop("engine", ""))
        engineParameters: root.renderer.prop("engine_parameters", {}) || {}
        volume: Number(root.renderer.prop("volume", 1))
        rate: Number(root.renderer.prop("rate", 0))
        pitch: Number(root.renderer.prop("pitch", 0))
        locale: {
          var localeName = String(root.renderer.prop("locale", ""))
          return localeName === "" ? Qt.locale() : Qt.locale(localeName)
        }
        VoiceSelector.name: String(root.renderer.prop("voice", ""))
        VoiceSelector.gender: root.genderValue()
        VoiceSelector.age: root.ageValue()
        onStateChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName,
          root.renderer.controlId, "state", {
            value: root.stateName(nativeSpeech.state), native_state: Number(nativeSpeech.state)
          })
        onSayingWord: function(word, id, start, length) {
          root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId,
            "word", { word: word, utterance_id: Number(id), start: Number(start), length: Number(length) })
        }
        onVoiceChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName,
          root.renderer.controlId, "voice_change", {
            name: nativeSpeech.voice.name, gender: Number(nativeSpeech.voice.gender),
            age: Number(nativeSpeech.voice.age), locale: String(nativeSpeech.voice.locale)
          })
        onEngineChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName,
          root.renderer.controlId, "engines", {
            current: nativeSpeech.engine, available: nativeSpeech.availableEngines()
          })
        onErrorOccurred: function(reason, message) {
          root.renderer.componentError("text_to_speech_failed", message,
            { native_code: Number(reason) })
        }
      }
    }
    onLoaded: root.runPendingCommand()
  }
  Component.onCompleted: processCommand()
  Connections { target: renderer; function onNodeChanged() { root.processCommand() } }
}
