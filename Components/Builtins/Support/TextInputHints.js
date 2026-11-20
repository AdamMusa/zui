.pragma library

function flagTable() {
  return {
    hidden_text: Qt.ImhHiddenText,
    sensitive_data: Qt.ImhSensitiveData,
    no_auto_uppercase: Qt.ImhNoAutoUppercase,
    prefer_numbers: Qt.ImhPreferNumbers,
    prefer_uppercase: Qt.ImhPreferUppercase,
    prefer_lowercase: Qt.ImhPreferLowercase,
    no_predictive_text: Qt.ImhNoPredictiveText,
    date: Qt.ImhDate,
    time: Qt.ImhTime,
    prefer_latin: Qt.ImhPreferLatin,
    multi_line: Qt.ImhMultiLine,
    no_edit_menu: Qt.ImhNoEditMenu,
    no_text_handles: Qt.ImhNoTextHandles,
    digits_only: Qt.ImhDigitsOnly,
    formatted_numbers_only: Qt.ImhFormattedNumbersOnly,
    uppercase_only: Qt.ImhUppercaseOnly,
    lowercase_only: Qt.ImhLowercaseOnly,
    dialable_characters_only: Qt.ImhDialableCharactersOnly,
    email_characters_only: Qt.ImhEmailCharactersOnly,
    url_characters_only: Qt.ImhUrlCharactersOnly,
    latin_only: Qt.ImhLatinOnly
  }
}

function enterKeyTable() {
  return {
    "default": Qt.EnterKeyDefault,
    "return": Qt.EnterKeyReturn,
    done: Qt.EnterKeyDone,
    go: Qt.EnterKeyGo,
    send: Qt.EnterKeySend,
    search: Qt.EnterKeySearch,
    next: Qt.EnterKeyNext,
    previous: Qt.EnterKeyPrevious
  }
}

function hints(requested) {
  if (!Array.isArray(requested)) return Qt.ImhNone
  var table = flagTable()
  var value = Qt.ImhNone
  for (var index = 0; index < requested.length; index++) {
    var flag = table[String(requested[index])]
    if (flag !== undefined) value |= flag
  }
  return value
}

function enterKey(requested) {
  var value = enterKeyTable()[String(requested)]
  return value === undefined ? Qt.EnterKeyDefault : value
}
