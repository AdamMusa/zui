import QtQuick
import QtCore

Item {
  id: root
  required property var renderer
  property int handledRefreshRevision: -1
  visible: false

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "information", {
      word_size: Number(SystemInformation.wordSize),
      byte_order: Number(SystemInformation.byteOrder),
      build_cpu_architecture: String(SystemInformation.buildCpuArchitecture),
      current_cpu_architecture: String(SystemInformation.currentCpuArchitecture),
      build_abi: String(SystemInformation.buildAbi),
      kernel_type: String(SystemInformation.kernelType),
      kernel_version: String(SystemInformation.kernelVersion),
      product_type: String(SystemInformation.productType),
      product_version: String(SystemInformation.productVersion),
      pretty_product_name: String(SystemInformation.prettyProductName),
      machine_host_name: String(SystemInformation.machineHostName),
      machine_unique_id: String(SystemInformation.machineUniqueId),
      boot_unique_id: String(SystemInformation.bootUniqueId)
    })
  }

  function refresh() {
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
  }

  Component.onCompleted: refresh()
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
}
