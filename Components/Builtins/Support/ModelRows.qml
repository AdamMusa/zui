import QtQuick

// Shared row handling for the model adapters that rebuild a ListModel from
// the rows Ruby declared.
//
// A plain ListModel fixes a role's TYPE on first append and clear() does not
// drop its roles, so rebuilding a model whose row shape Ruby has changed makes
// Qt log "Can't assign to existing role 'x' of different type" and keep an
// empty value. Dynamic roles avoid that entirely; this helper also detects the
// conflict so an adapter that was asked for fixed roles can still report it
// instead of quietly losing data.
QtObject {
  id: modelRows

  property var appliedTypes: ({})

  function normalize(items) {
    if (!Array.isArray(items)) return []
    var rows = []
    for (var index = 0; index < items.length; index++) {
      var item = items[index]
      rows.push(item !== null && typeof item === "object" && !Array.isArray(item)
        ? item : { value: item })
    }
    return rows
  }

  function typesOf(rows) {
    var types = {}
    for (var index = 0; index < rows.length; index++) {
      var row = rows[index]
      for (var key in row) {
        if (types[key] === undefined) types[key] = typeof row[key]
      }
    }
    return types
  }

  // Returns the roles whose type changed since the last fill, which a
  // fixed-role ListModel cannot represent.
  function conflicts(rows) {
    var types = typesOf(rows)
    var changed = []
    for (var key in types) {
      var previous = appliedTypes[key]
      if (previous !== undefined && previous !== types[key]) {
        changed.push({ role: key, was: previous, now: types[key] })
      }
    }
    return changed
  }

  function fill(model, rows) {
    model.clear()
    for (var index = 0; index < rows.length; index++) model.append(rows[index])
    var types = typesOf(rows)
    for (var key in types) appliedTypes[key] = types[key]
  }
}
