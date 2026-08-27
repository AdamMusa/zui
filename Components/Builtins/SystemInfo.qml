import QtQuick
import QtCore

Item {
  id: root
  required property var renderer
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

  Component.onCompleted: publish()
  Connections { target: renderer; function onNodeChanged() { root.publish() } }
}
