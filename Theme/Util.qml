pragma Singleton
import QtQuick

QtObject {
  function alpha(color, opacity) { return Qt.rgba(color.r, color.g, color.b, Number(opacity)) }

  function isScalableImageSource(source) {
    var normalized = String(source || "").split("?")[0].split("#")[0].toLowerCase()
    return normalized.endsWith(".svg") || normalized.endsWith(".svgz")
  }

  function scalableImageSourceSize(source, requestedSize, targetSize, devicePixelRatio) {
    var requested = Number(requestedSize)
    if (isFinite(requested) && requested > 0)
      return requested

    var target = Number(targetSize)
    if (!isScalableImageSource(source) || !isFinite(target) || target <= 0)
      return -1

    var ratio = Math.max(1, Number(devicePixelRatio) || 1)
    return Math.max(1, Math.ceil(target * ratio))
  }
}
