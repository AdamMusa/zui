pragma Singleton
import QtQuick

QtObject {
  function none() {
    return ({ color: "transparent", widths: ({ top: 0, right: 0, bottom: 0, left: 0 }) })
  }

  function widths(value) {
    if (typeof value === "object") return value
    var width = Number(value || 0)
    return ({ top: width, right: width, bottom: width, left: width })
  }

  function flat(color, width) {
    return ({ color: color, widths: widths(width), gradient: ({ enabled: false, colors: [] }) })
  }

  function controlSpec(_kind, color, _accent) {
    return flat(color, 1)
  }
}
