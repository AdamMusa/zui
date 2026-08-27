import QtQuick
import QtTextToSpeech

Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
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
    if (first && renderer.prop("auto_speak", false) === true && text !== "") nativeSpeech.say(text)
    else if (!first || revision > 0) {
      if (command === "say") nativeSpeech.say(text)
      else if (command === "enqueue") nativeSpeech.enqueue(text)
      else if (command === "stop") nativeSpeech.stop()
      else if (command === "pause") nativeSpeech.pause()
      else if (command === "resume") nativeSpeech.resume()
    }
  }
  TextToSpeech {
    id: nativeSpeech
    engine: String(root.renderer.prop("engine", ""))
    engineParameters: root.renderer.prop("engine_parameters", {}) || {}
    volume: Number(root.renderer.prop("volume", 1))
    rate: Number(root.renderer.prop("rate", 0))
    pitch: Number(root.renderer.prop("pitch", 0))
    locale: String(root.renderer.prop("locale", ""))
    VoiceSelector.name: String(root.renderer.prop("voice", ""))
    VoiceSelector.gender: root.genderValue()
    VoiceSelector.age: root.ageValue()
    onStateChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "state", { value: root.stateName(state), native_state: Number(state) })
    onSayingWord: function(word, id, start, length) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "word", { word: word, utterance_id: Number(id), start: Number(start), length: Number(length) }) }
    onVoiceChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "voice_change", { name: voice.name, gender: Number(voice.gender), age: Number(voice.age), locale: String(voice.locale) })
    onEngineChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "engines", { current: engine, available: availableEngines() })
    onErrorOccurred: function(reason, message) { renderer.componentError("text_to_speech_failed", message, { native_code: Number(reason) }) }
  }
  Component.onCompleted: processCommand()
  Connections { target: renderer; function onNodeChanged() { root.processCommand() } }
}
