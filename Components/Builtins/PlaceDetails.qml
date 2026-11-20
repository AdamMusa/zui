import QtQuick
import QtLocation
import QtPositioning
import "Support" as Support

Item {
  id: root
  required property var renderer
  property var parameterObjects: []
  property int handledCommandRevision: -1
  property string pendingOperation: "details"
  visible: false

  function configurePlugin() {
    for (var oldIndex = 0; oldIndex < parameterObjects.length; oldIndex++) parameterObjects[oldIndex].destroy()
    var objects = []
    var values = renderer.prop("plugin_parameters", {}) || {}
    var names = Object.keys(values).sort()
    for (var index = 0; index < names.length; index++)
      objects.push(parameterComponent.createObject(root, { name: names[index], value: values[names[index]] }))
    parameterObjects = objects
    nativePlugin.parameters = objects
    nativePlugin.name = String(renderer.prop("plugin", "osm"))
  }

  function visibilityValue() {
    var value = String(renderer.prop("visibility", "unspecified"))
    if (value === "device") return Place.DeviceVisibility
    if (value === "private") return Place.PrivateVisibility
    if (value === "public") return Place.PublicVisibility
    return Place.UnspecifiedVisibility
  }

  function statusName(value) { return ["ready", "saving", "fetching", "removing", "error"][Number(value)] || "unknown" }

  function publish(eventName) {
    var coordinate = nativePlace.location.coordinate
    var address = nativePlace.location.address
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, {
      place_id: String(nativePlace.placeId), name: String(nativePlace.name), attribution: String(nativePlace.attribution),
      latitude: coordinate.latitude, longitude: coordinate.longitude, altitude: coordinate.altitude,
      address: { text: String(address.text), country: String(address.country), country_code: String(address.countryCode),
        state: String(address.state), county: String(address.county), city: String(address.city), district: String(address.district),
        street: String(address.street), postal_code: String(address.postalCode) }, phone: String(nativePlace.primaryPhone),
      fax: String(nativePlace.primaryFax), email: String(nativePlace.primaryEmail), website: String(nativePlace.primaryWebsite),
      details_fetched: nativePlace.detailsFetched,
      categories: categoryPayload(),
      ratings: { average: Number(nativePlace.ratings.average), maximum: Number(nativePlace.ratings.maximum),
        count: Number(nativePlace.ratings.count) },
      supplier: contentReader.supplierPayload(nativePlace.supplier),
      icon_url: String(nativePlace.icon.url()),
      contacts: contactPayload(),
      extended_attributes_available: nativePlace.extendedAttributes !== null
    })
  }

  // ContactDetails is a QQmlPropertyMap of contact type to a list of contactDetail values,
  // so it is read by the keys the provider actually filled in rather than a fixed set.
  readonly property var contactKeys: ["phone", "fax", "email", "website"]
  function contactPayload() {
    var details = {}
    for (var index = 0; index < contactKeys.length; index++) {
      var key = contactKeys[index]
      var values = nativePlace.contactDetails[key]
      if (values === undefined || values === null) continue
      var entries = []
      for (var entry = 0; entry < values.length; entry++)
        entries.push({ label: String(values[entry].label), value: String(values[entry].value) })
      details[key] = entries
    }
    return details
  }

  function categoryPayload() {
    var values = []
    var categories = nativePlace.categories || []
    for (var index = 0; index < categories.length; index++)
      values.push({ category_id: String(categories[index].categoryId), name: String(categories[index].name) })
    return values
  }

  // QDeclarativePlaceContentModel::fetchMore is not in Qt 6.8.3's QML type data, so there
  // is no way to ask for another batch from QML; batch_size is what decides how much
  // content the provider returns when the place's details are fetched.
  function publishContent() {
    var reviews = []
    for (var r = 0; r < reviewRows.count; r++) {
      var review = reviewRows.itemAt(r)
      if (!review) continue
      reviews.push(contentReader.merge(contentReader.commonPayload(review), {
        index: r, review_id: String(review.reviewId), title: String(review.title),
        text: String(review.text), language: String(review.language), rating: Number(review.rating),
        date_time: review.dateTime && !isNaN(review.dateTime.getTime()) ? review.dateTime.toISOString() : ""
      }))
    }
    var images = []
    for (var i = 0; i < imageRows.count; i++) {
      var image = imageRows.itemAt(i)
      if (!image) continue
      images.push(contentReader.merge(contentReader.commonPayload(image), {
        index: i, image_id: String(image.imageId), url: String(image.url), mime_type: String(image.mimeType)
      }))
    }
    var editorials = []
    for (var e = 0; e < editorialRows.count; e++) {
      var editorial = editorialRows.itemAt(e)
      if (!editorial) continue
      editorials.push(contentReader.merge(contentReader.commonPayload(editorial), {
        index: e, title: String(editorial.title), text: String(editorial.text),
        language: String(editorial.language)
      }))
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "content", {
      reviews: reviews, review_total: Number(nativePlace.reviewModel.totalCount),
      images: images, image_total: Number(nativePlace.imageModel.totalCount),
      editorials: editorials, editorial_total: Number(nativePlace.editorialModel.totalCount)
    })
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", "details"))
    pendingOperation = command
    if (command === "save") nativePlace.save()
    else if (command === "remove") nativePlace.remove()
    else nativePlace.getDetails()
  }

  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  Location {
    id: nativeLocation
    coordinate: QtPositioning.coordinate(Number(root.renderer.prop("latitude", 0)),
      Number(root.renderer.prop("longitude", 0)), Number(root.renderer.prop("altitude", 0)))
  }
  Place {
    id: nativePlace
    plugin: nativePlugin
    placeId: String(root.renderer.prop("place_id", ""))
    name: String(root.renderer.prop("name", ""))
    attribution: String(root.renderer.prop("attribution", ""))
    visibility: root.visibilityValue()
    location: nativeLocation
    onStatusChanged: {
      var name = root.statusName(status)
      root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "status", { value: name })
      if (name === "ready") {
        var eventName = root.pendingOperation === "remove" ? "removed"
          : (root.pendingOperation === "save" ? "saved" : "details")
        root.publish(eventName)
      }
      else if (name === "error") root.renderer.componentError("place_operation_failed", errorString(), {})
    }
  }
  Support.PlaceContentReader { id: contentReader }
  Repeater {
    id: reviewRows
    model: nativePlace.reviewModel
    delegate: Item {
      required property var supplier
      required property var user
      required property string attribution
      required property string reviewId
      required property string title
      required property string text
      required property string language
      required property real rating
      required property var dateTime
    }
    onCountChanged: contentTimer.restart()
  }
  Repeater {
    id: imageRows
    model: nativePlace.imageModel
    delegate: Item {
      required property var supplier
      required property var user
      required property string attribution
      required property string imageId
      required property url url
      required property string mimeType
    }
    onCountChanged: contentTimer.restart()
  }
  Repeater {
    id: editorialRows
    model: nativePlace.editorialModel
    delegate: Item {
      required property var supplier
      required property var user
      required property string attribution
      required property string title
      required property string text
      required property string language
    }
    onCountChanged: contentTimer.restart()
  }
  Binding { target: nativePlace.reviewModel; property: "batchSize"; value: Number(root.renderer.prop("batch_size", 10)) }
  Binding { target: nativePlace.imageModel; property: "batchSize"; value: Number(root.renderer.prop("batch_size", 10)) }
  Binding { target: nativePlace.editorialModel; property: "batchSize"; value: Number(root.renderer.prop("batch_size", 10)) }
  // Content rows arrive one delegate at a time, so coalesce them into a single event.
  Timer { id: contentTimer; interval: 16; repeat: false; onTriggered: root.publishContent() }

  Component.onCompleted: { configurePlugin(); publish("details"); processCommand() }
  Connections { target: renderer; function onNodeChanged() { root.configurePlugin(); root.processCommand() } }
}
