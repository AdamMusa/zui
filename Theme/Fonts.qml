pragma Singleton
import QtQuick

QtObject {
  readonly property FontLoader regularLoader: FontLoader {
    source: zuiBundledFontsReady ? "" : Qt.resolvedUrl("../Fonts/RobotoMono-Regular.otf")
  }
  readonly property FontLoader boldLoader: FontLoader {
    source: zuiBundledFontsReady ? "" : Qt.resolvedUrl("../Fonts/RobotoMono-Bold.otf")
  }
  readonly property FontLoader iconLoader: FontLoader {
    source: zuiBundledFontsReady ? "" : Qt.resolvedUrl("../Fonts/FontAwesome-Solid.otf")
  }
  readonly property FontLoader brandIconLoader: FontLoader {
    source: zuiBundledFontsReady ? "" : Qt.resolvedUrl("../Fonts/FontAwesome-Brands.otf")
  }

  readonly property string family: zuiBundledFontsReady ? zuiBundledTextFont
    : regularLoader.status === FontLoader.Ready
    ? regularLoader.name : ""
  readonly property string iconFamily: zuiBundledFontsReady ? zuiBundledIconFont
    : iconLoader.status === FontLoader.Ready
    ? iconLoader.name : family
  readonly property string brandIconFamily: zuiBundledFontsReady ? zuiBundledBrandIconFont
    : brandIconLoader.status === FontLoader.Ready
    ? brandIconLoader.name : iconFamily
  readonly property bool ready: zuiBundledFontsReady || (regularLoader.status === FontLoader.Ready
    && boldLoader.status === FontLoader.Ready
    && iconLoader.status === FontLoader.Ready
    && brandIconLoader.status === FontLoader.Ready)
  readonly property bool failed: !zuiBundledFontsReady && (regularLoader.status === FontLoader.Error
    || boldLoader.status === FontLoader.Error
    || iconLoader.status === FontLoader.Error
    || brandIconLoader.status === FontLoader.Error)
}
