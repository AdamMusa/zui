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

  // Never hand Qt an empty family. Until the bundled faces finish loading this
  // resolved to "", and a Text in RichText or MarkdownText format then falls
  // back to the CSS default "Sans-serif", which no system provides. Resolving
  // that miss makes Qt populate every font family alias on the machine, a
  // one-off cost of over two seconds that lands squarely in application
  // startup. The application's own default family always exists.
  readonly property string family: zuiBundledFontsReady ? zuiBundledTextFont
    : regularLoader.status === FontLoader.Ready
    ? regularLoader.name : Qt.application.font.family
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
