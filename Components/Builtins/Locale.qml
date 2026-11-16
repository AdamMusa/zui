import QtQuick
import QtQml

// QtQml's Locale type is an uncreatable namespace: the usable locale is the
// value Qt.locale() returns, and Locale itself supplies the format enums.
// Qt owns CLDR data that Ruby has no access to, so this adapter answers
// locale questions and formatting requests rather than wrapping an object.
Item {
  id: localeRoot

  required property var renderer
  property string handledRequestKey: ""

  readonly property string requestedName: String(renderer.prop("name", ""))
  readonly property var locale: requestedName === "" ? Qt.locale() : Qt.locale(requestedName)

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function formatType(value, fallback) {
    var name = String(value === undefined || value === null ? fallback : value)
    if (name === "short") return Locale.ShortFormat
    if (name === "narrow") return Locale.NarrowFormat
    return Locale.LongFormat
  }

  function currencyFormat() {
    var name = String(renderer.prop("currency_format", "symbol"))
    if (name === "iso") return Locale.CurrencyIsoCode
    if (name === "display_name") return Locale.CurrencyDisplayName
    return Locale.CurrencySymbol
  }

  function dataSizeFormat() {
    var name = String(renderer.prop("data_size_format", "iec"))
    if (name === "si") return Locale.DataSizeSIFormat
    if (name === "traditional") return Locale.DataSizeTraditionalFormat
    if (name === "base1000") return Locale.DataSizeBase1000
    return Locale.DataSizeIecFormat
  }

  function dayOfWeekName(value) {
    var names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    var index = Number(value)
    return names[index] === undefined ? "" : names[index]
  }

  function measurementSystemName() {
    var value = Number(locale.measurementSystem)
    if (value === 1) return "imperial_us"
    if (value === 2) return "imperial_uk"
    return "metric"
  }

  function textDirectionName() {
    return Number(locale.textDirection) === Qt.RightToLeft ? "right_to_left" : "left_to_right"
  }

  function nameList(accessor, count, type) {
    var values = []
    for (var index = 0; index < count; index++) values.push(String(accessor(index, type)))
    return values
  }

  function parsedDate(value) {
    var text = String(value === undefined || value === null ? "" : value)
    if (text === "") return null
    var parsed = new Date(text)
    return isNaN(parsed.getTime()) ? null : parsed
  }

  function requestKey() {
    return [requestedName, String(renderer.prop("format", "long")),
      String(renderer.prop("number", "")), String(renderer.prop("precision", "")),
      String(renderer.prop("currency", "")), String(renderer.prop("currency_format", "")),
      String(renderer.prop("date", "")), String(renderer.prop("time", "")),
      String(renderer.prop("date_time", "")), String(renderer.prop("data_size", "")),
      String(renderer.prop("data_size_format", "")),
      String(renderer.prop("refresh_revision", 0))].join("\u001f")
  }

  function publishInformation() {
    var type = formatType(renderer.prop("format", "long"), "long")
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "information", {
      name: String(locale.name),
      native_language_name: String(locale.nativeLanguageName),
      native_territory_name: String(locale.nativeTerritoryName),
      ui_languages: locale.uiLanguages.map(String),
      decimal_point: String(locale.decimalPoint),
      group_separator: String(locale.groupSeparator),
      percent: String(locale.percent),
      zero_digit: String(locale.zeroDigit),
      negative_sign: String(locale.negativeSign),
      positive_sign: String(locale.positiveSign),
      exponential: String(locale.exponential),
      am_text: String(locale.amText),
      pm_text: String(locale.pmText),
      first_day_of_week: Number(locale.firstDayOfWeek),
      first_day_of_week_name: dayOfWeekName(locale.firstDayOfWeek),
      week_days: locale.weekDays.map(Number),
      measurement_system: measurementSystemName(),
      text_direction: textDirectionName(),
      currency_symbol: String(locale.currencySymbol(Locale.CurrencySymbol)),
      currency_iso_code: String(locale.currencySymbol(Locale.CurrencyIsoCode)),
      currency_display_name: String(locale.currencySymbol(Locale.CurrencyDisplayName)),
      date_format: String(locale.dateFormat(type)),
      time_format: String(locale.timeFormat(type)),
      date_time_format: String(locale.dateTimeFormat(type)),
      month_names: nameList(locale.monthName, 12, type),
      standalone_month_names: nameList(locale.standaloneMonthName, 12, type),
      day_names: nameList(locale.dayName, 7, type),
      standalone_day_names: nameList(locale.standaloneDayName, 7, type)
    })
  }

  function publishFormatted() {
    var type = formatType(renderer.prop("format", "long"), "long")
    var payload = {}

    var number = renderer.prop("number", null)
    if (number !== null) {
      var precision = renderer.prop("precision", null)
      payload.number = precision === null
        ? Number(number).toLocaleString(locale)
        : Number(number).toLocaleString(locale, "f", Math.floor(Number(precision)))
    }

    var currency = renderer.prop("currency", null)
    if (currency !== null) {
      payload.currency = Number(currency)
        .toLocaleCurrencyString(locale, String(locale.currencySymbol(currencyFormat())))
    }

    var date = parsedDate(renderer.prop("date", null))
    if (date) payload.date = date.toLocaleDateString(locale, type)

    var time = parsedDate(renderer.prop("time", null))
    if (time) payload.time = time.toLocaleTimeString(locale, type)

    var dateTime = parsedDate(renderer.prop("date_time", null))
    if (dateTime) payload.date_time = dateTime.toLocaleString(locale, type)

    var dataSize = renderer.prop("data_size", null)
    if (dataSize !== null) {
      var digits = Math.floor(Number(renderer.prop("precision", 2)))
      payload.data_size = String(locale.formattedDataSize(Number(dataSize), digits, dataSizeFormat()))
    }

    if (Object.keys(payload).length === 0) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "formatted", payload)
  }

  // Qt.locale() answers an unknown name with the C locale rather than failing,
  // which would quietly format everything the wrong way.
  function resolve() {
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key

    if (requestedName !== "" && requestedName !== "C" && String(locale.name) === "C") {
      renderer.componentError("locale_unavailable",
        "Qt has no data for locale " + requestedName + " and fell back to the C locale",
        { name: requestedName })
      return
    }
    publishInformation()
    publishFormatted()
  }

  Component.onCompleted: resolve()
  Connections { target: renderer; function onNodeChanged() { localeRoot.resolve() } }
}
