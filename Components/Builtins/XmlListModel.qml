import QtQuick
import QtQml.XmlListModel

Item {
  id: xmlRoot

  required property var renderer
  property alias model: nativeModel
  property string handledRequestKey: ""
  property var appliedRoles: []

  // XmlListModel assigns its roles sequentially from Qt::UserRole in the order
  // they appear in its roles list, so the declaration order is the read order.
  readonly property int firstRole: 256

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function requestedRoles() {
    var specs = []
    var declared = renderer.prop("roles", [])
    if (Array.isArray(declared)) {
      for (var index = 0; index < declared.length; index++) {
        var spec = declared[index]
        if (spec === null || typeof spec !== "object") continue
        specs.push({
          name: String(spec.name === undefined ? "" : spec.name),
          element_name: String(spec.element_name === undefined ? "" : spec.element_name),
          attribute_name: String(spec.attribute_name === undefined ? "" : spec.attribute_name)
        })
      }
    }
    var children = renderer.node && Array.isArray(renderer.node.children)
      ? renderer.node.children : []
    for (var child = 0; child < children.length; child++) {
      var node = children[child]
      if (!node || String(node.type) !== "xml_list_model_role") continue
      var props = node.props || {}
      specs.push({
        name: String(props.name === undefined ? "" : props.name),
        element_name: String(props.element_name === undefined ? "" : props.element_name),
        attribute_name: String(props.attribute_name === undefined ? "" : props.attribute_name)
      })
    }
    return specs.filter(function(spec) { return spec.name !== "" })
  }

  function requestKey() {
    return [String(renderer.prop("source", "")), String(renderer.prop("query", "")),
      JSON.stringify(requestedRoles()),
      String(renderer.prop("reload_revision", 0))].join("\u001f")
  }

  function statusName(value) {
    if (value === XmlListModel.Ready) return "ready"
    if (value === XmlListModel.Loading) return "loading"
    if (value === XmlListModel.Error) return "error"
    return "null"
  }

  function rows() {
    var specs = appliedRoles
    var result = []
    for (var row = 0; row < nativeModel.count; row++) {
      var modelIndex = nativeModel.index(row, 0)
      var values = {}
      for (var role = 0; role < specs.length; role++) {
        var value = nativeModel.data(modelIndex, firstRole + role)
        values[specs[role].name] = value === undefined ? "" : value
      }
      result.push(values)
    }
    return result
  }

  function applyRoles() {
    var specs = requestedRoles()
    var created = []
    for (var index = 0; index < specs.length; index++) {
      created.push(roleFactory.createObject(nativeModel, {
        name: specs[index].name,
        elementName: specs[index].element_name,
        attributeName: specs[index].attribute_name
      }))
    }
    appliedRoles = specs
    nativeModel.roles = created
  }

  function reload() {
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key
    applyRoles()
    nativeModel.reload()
  }

  Component { id: roleFactory; XmlListModelRole {} }

  XmlListModel {
    id: nativeModel
    source: renderer.assetUrl(renderer.prop("source", ""))
    query: String(renderer.prop("query", "/"))

    onStatusChanged: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", {
        value: xmlRoot.statusName(status), count: count, progress: progress
      })
      if (status === XmlListModel.Error) {
        renderer.componentError("xml_list_model_error", errorString(),
          { source: String(source), query: query })
        return
      }
      if (status !== XmlListModel.Ready) return

      var values = xmlRoot.rows()
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "loaded",
        { values: values, count: count })
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change",
        { values: values, count: count })
    }
    onProgressChanged: function(value) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "progress", { value: value })
    }
    onCountChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "count_change", { value: count })
  }

  Component.onCompleted: reload()
  Connections { target: renderer; function onNodeChanged() { xmlRoot.reload() } }
}
