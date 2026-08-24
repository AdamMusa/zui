pragma Singleton
import QtQuick

QtObject {
  readonly property FontLoader regularLoader: FontLoader {
    source: Qt.resolvedUrl("../Fonts/RobotoMono-Regular.otf")
  }
  readonly property FontLoader boldLoader: FontLoader {
    source: Qt.resolvedUrl("../Fonts/RobotoMono-Bold.otf")
  }
  readonly property FontLoader iconLoader: FontLoader {
    source: Qt.resolvedUrl("../Fonts/FontAwesome-Solid.otf")
  }
  readonly property FontLoader brandIconLoader: FontLoader {
    source: Qt.resolvedUrl("../Fonts/FontAwesome-Brands.otf")
  }

  readonly property string family: regularLoader.status === FontLoader.Ready
    ? regularLoader.name : ""
  readonly property string iconFamily: iconLoader.status === FontLoader.Ready
    ? iconLoader.name : family
  readonly property string brandIconFamily: brandIconLoader.status === FontLoader.Ready
    ? brandIconLoader.name : iconFamily
  readonly property bool ready: regularLoader.status === FontLoader.Ready
    && boldLoader.status === FontLoader.Ready
    && iconLoader.status === FontLoader.Ready
    && brandIconLoader.status === FontLoader.Ready
  readonly property bool failed: regularLoader.status === FontLoader.Error
    || boldLoader.status === FontLoader.Error
    || iconLoader.status === FontLoader.Error
    || brandIconLoader.status === FontLoader.Error
}
