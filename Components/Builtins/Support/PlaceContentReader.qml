import QtQuick

// ReviewModel, ImageModel and EditorialModel are all isCreatable: false and reached only
// as Place.reviewModel / imageModel / editorialModel. They share
// QDeclarativePlaceContentModel, whose supplier, user and attribution roles are common to
// all three; the type-specific roles are read by the caller's own delegate.
QtObject {
  id: reader

  function supplierPayload(supplier) {
    if (!supplier) return null
    return { name: String(supplier.name), supplier_id: String(supplier.supplierId), url: String(supplier.url) }
  }

  function userPayload(user) {
    if (!user) return null
    return { user_id: String(user.userId), name: String(user.name) }
  }

  function commonPayload(row) {
    return { supplier: supplierPayload(row.supplier), user: userPayload(row.user),
      attribution: String(row.attribution) }
  }

  function merge(base, extra) {
    var names = Object.keys(extra)
    for (var index = 0; index < names.length; index++) base[names[index]] = extra[names[index]]
    return base
  }
}
