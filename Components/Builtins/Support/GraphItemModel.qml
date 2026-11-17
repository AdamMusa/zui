import QtQuick
import QtQml.Models

// QtGraphs' item-model data proxies read a QAbstractItemModel and address its
// data by role *name* - rowRole, columnRole, valueRole. zui applications own no
// Qt item models, so this turns an array of plain objects into one.
//
// A ListModel with dynamicRoles takes its role names from the keys of the
// objects appended to it, which is exactly what those proxies need. The
// TableModel used for the 2D chart mappers cannot serve here: its roles are
// Qt's own display/edit roles, not names a proxy can ask for.
ListModel {
  id: itemModel

  dynamicRoles: true
  property var rowValues: []

  function refresh() {
    itemModel.clear()
    var source = Array.isArray(itemModel.rowValues) ? itemModel.rowValues : []
    for (var index = 0; index < source.length; index++) {
      var row = source[index]
      if (row === null || typeof row !== "object" || Array.isArray(row)) continue
      itemModel.append(row)
    }
  }

  onRowValuesChanged: itemModel.refresh()
  Component.onCompleted: itemModel.refresh()
}
