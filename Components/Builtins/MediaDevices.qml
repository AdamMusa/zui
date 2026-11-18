import QtQuick
import QtMultimedia

Item {
  id: devicesRoot
  property var renderer: null

  readonly property var audioModeNames: ["null", "input", "output"]
  readonly property var cameraPositionNames: ["unspecified", "back", "front"]

  // QAudioDevice and QCameraDevice are isCreatable: false - they reach QML only as entries
  // of MediaDevices' lists, so each one is reported as a payload shape here.
  function audioPayload(device) {
    if (!device) return null
    return { id: String(device.id), description: String(device.description),
      default: device.isDefault === true, mode: Number(device.mode),
      mode_name: devicesRoot.audioModeNames[Number(device.mode)] || "null" }
  }
  function cameraFormats(device) {
    var formats = []
    var values = device.videoFormats || []
    for (var index = 0; index < values.length; index++) {
      var format = values[index]
      formats.push({ width: Number(format.resolution.width), height: Number(format.resolution.height),
        pixel_format: Number(format.pixelFormat),
        minimum_frame_rate: Number(format.minFrameRate), maximum_frame_rate: Number(format.maxFrameRate) })
    }
    return formats
  }
  function cameraPayload(device) {
    if (!device) return null
    return { id: String(device.id), description: String(device.description),
      default: device.isDefault === true, position: Number(device.position),
      position_name: devicesRoot.cameraPositionNames[Number(device.position)] || "unspecified",
      correction_angle: Number(device.correctionAngle),
      formats: devicesRoot.cameraFormats(device) }
  }
  function audioList(list) {
    var values = []
    for (var index = 0; index < list.length; index++) values.push(devicesRoot.audioPayload(list[index]))
    return values
  }
  function cameraList(list) {
    var values = []
    for (var index = 0; index < list.length; index++) values.push(devicesRoot.cameraPayload(list[index]))
    return values
  }
  function emitAll() {
    if (!renderer) return
    var kind = String(renderer.prop("kind", "all"))
    if (kind === "all" || kind === "video_inputs")
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "video_inputs",
        { values: devicesRoot.cameraList(nativeDevices.videoInputs),
          default: devicesRoot.cameraPayload(nativeDevices.defaultVideoInput) })
    if (kind === "all" || kind === "audio_inputs")
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "audio_inputs",
        { values: devicesRoot.audioList(nativeDevices.audioInputs),
          default: devicesRoot.audioPayload(nativeDevices.defaultAudioInput) })
    if (kind === "all" || kind === "audio_outputs")
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "audio_outputs",
        { values: devicesRoot.audioList(nativeDevices.audioOutputs),
          default: devicesRoot.audioPayload(nativeDevices.defaultAudioOutput) })
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change",
      { kind: kind, revision: Number(renderer.prop("refresh_revision", 0)) })
  }
  MediaDevices {
    id: nativeDevices
    onVideoInputsChanged: devicesRoot.emitAll()
    onAudioInputsChanged: devicesRoot.emitAll()
    onAudioOutputsChanged: devicesRoot.emitAll()
  }
  Component.onCompleted: emitAll()
  Connections { target: renderer; function onNodeChanged() { devicesRoot.emitAll() } }
}
