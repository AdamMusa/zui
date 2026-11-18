import QtQuick
import QtMultimedia

// QMediaMetaData is isCreatable: false - it reaches QML only as MediaPlayer.metaData or
// MediaRecorder.metaData. This turns one of those values into a payload, naming each
// QMediaMetaData::Key the way the rest of the protocol names things.
QtObject {
  id: reader

  readonly property var keyNames: [
    "title", "author", "comment", "description", "genre", "date", "language", "publisher",
    "copyright", "url", "duration", "media_type", "file_format", "audio_bit_rate",
    "audio_codec", "video_bit_rate", "video_codec", "video_frame_rate", "album_title",
    "album_artist", "contributing_artist", "track_number", "composer", "lead_performer",
    "thumbnail_image", "cover_art_image", "orientation", "resolution", "has_hdr_content"
  ]

  function keyName(key) {
    var index = Number(key)
    return index >= 0 && index < keyNames.length ? keyNames[index] : "key_" + index
  }

  function payload(metaData) {
    var values = {}
    var names = []
    if (!metaData) return { values: values, keys: names, empty: true }
    var keys = metaData.keys()
    for (var index = 0; index < keys.length; index++) {
      var key = keys[index]
      var name = keyName(key)
      names.push(name)
      // Image keys hold a QImage, which has no useful JSON form; report that one is
      // present rather than serialising it or dropping the key silently.
      if (name === "thumbnail_image" || name === "cover_art_image") values[name] = true
      else values[name] = metaData.stringValue(key)
    }
    return { values: values, keys: names, empty: metaData.isEmpty() === true }
  }
}
