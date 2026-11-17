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
  readonly property var genderNames: ["male", "female", "unknown"]
  readonly property var ageNames: ["child", "teenager", "adult", "senior", "other"]
  // QVoice is isCreatable: false - it reaches QML only as TextToSpeech.voice or as an
  // entry of availableVoices()/findVoices(), so it is reported as a payload shape.
  function voicePayload(voice) {
    if (!voice) return null
    return { name: String(voice.name), gender: Number(voice.gender),
      gender_name: genderNames[Number(voice.gender)] || "unknown",
      age: Number(voice.age), age_name: ageNames[Number(voice.age)] || "other",
      locale: String(voice.locale.name), language: Number(voice.language) }
  }
  function voiceList(voices) {
    var values = []
    for (var index = 0; index < voices.length; index++) values.push(voicePayload(voices[index]))
    return values
  }
  function localeList(locales) {
    var values = []
    for (var index = 0; index < locales.length; index++) values.push(String(locales[index].name))
    return values
  }
  function capabilityNames(flags) {
    var names = []
    var value = Number(flags)
    if (value & 1) names.push("speak")
    if (value & 2) names.push("pause_resume")
    if (value & 4) names.push("word_by_word_progress")
    if (value & 8) names.push("synthesize")
    return names
  }
  function publishVoices(nativeSpeech) {
    if (!nativeSpeech) return
    var criteria = renderer.prop("voice_criteria", null)
    var matched = criteria ? voiceList(nativeSpeech.findVoices(criteria)) : null
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "voices", {
      available: voiceList(nativeSpeech.availableVoices()),
      locales: localeList(nativeSpeech.availableLocales()),
      current: voicePayload(nativeSpeech.voice),
      matched: matched,
      capabilities: capabilityNames(nativeSpeech.engineCapabilities),
      native_capabilities: Number(nativeSpeech.engineCapabilities)
    })
  }
  function boundaryHint() {
    var value = String(renderer.prop("boundary_hint", "default"))
    if (value === "immediate") return TextToSpeech.BoundaryHint.Immediate
    if (value === "word") return TextToSpeech.BoundaryHint.Word
    if (value === "sentence") return TextToSpeech.BoundaryHint.Sentence
    if (value === "utterance") return TextToSpeech.BoundaryHint.Utterance
    return TextToSpeech.BoundaryHint.Default
  }
  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    var command = String(renderer.prop("command", ""))
    var text = String(renderer.prop("text", ""))
    var autoSpeak = first && renderer.prop("auto_speak", false) === true && text !== ""
    if (revision <= 0 && !autoSpeak) return
    if (autoSpeak) command = "say"
    if (["say", "enqueue", "stop", "pause", "resume", "voices"].indexOf(command) < 0) return
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
    else if (command === "stop") nativeSpeech.stop(root.boundaryHint())
    else if (command === "pause") nativeSpeech.pause(root.boundaryHint())
    else if (command === "resume") nativeSpeech.resume()
    else if (command === "voices") root.publishVoices(nativeSpeech)
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
        VoiceSelector.locale: {
          var name = String(root.renderer.prop("voice_locale", ""))
          return name === "" ? Qt.locale() : Qt.locale(name)
        }
        VoiceSelector.language: {
          var name = String(root.renderer.prop("voice_language", ""))
          return name === "" ? Qt.locale() : Qt.locale(name)
        }
        onStateChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName,
          root.renderer.controlId, "state", {
            value: root.stateName(nativeSpeech.state), native_state: Number(nativeSpeech.state)
          })
        onSayingWord: function(word, id, start, length) {
          root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId,
            "word", { word: word, utterance_id: Number(id), start: Number(start), length: Number(length) })
        }
        onVoiceChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName,
          root.renderer.controlId, "voice_change", root.voicePayload(nativeSpeech.voice) || {})
        onAboutToSynthesize: function(id) {
          root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId,
            "about_to_synthesize", { utterance_id: Number(id) })
        }
        Component.onCompleted: root.publishVoices(nativeSpeech)
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
