#include "ZuiClipboard.h"
#include "ZuiSafeArea.h"

#if defined(ZUI_EMBEDDED_CRUBY)
#include "ZuiCRubyRuntime.h"
using ZuiRuntimeTransport = ZuiCRubyRuntime;
#elif defined(ZUI_EMBEDDED_RUNTIME)
#include "ZuiEmbeddedRuntime.h"
using ZuiRuntimeTransport = ZuiEmbeddedRuntime;
#else
#include "ZuiProcess.h"
using ZuiRuntimeTransport = ZuiProcess;
#endif

#include <QCommandLineParser>
#include <QColor>
#include <QDebug>
#include <QDir>
#include <QElapsedTimer>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QTimer>

#if defined(ZUI_USES_WEBVIEW)
#include <QtWebView/QtWebView>
#endif

#if defined(Q_OS_DARWIN)
#include <malloc/malloc.h>
#endif

namespace {
struct BundledFonts {
  QString textFamily;
  QString iconFamily;
  QString brandIconFamily;
  bool ready = false;
};

BundledFonts installBundledFonts(const QString &qmlRoot) {
  const QDir fontsDirectory(QDir(qmlRoot).filePath(QStringLiteral("Fonts")));
  const QStringList fontFiles = {
      QStringLiteral("RobotoMono-Regular.otf"),
      QStringLiteral("RobotoMono-Bold.otf"),
      QStringLiteral("FontAwesome-Solid.otf"),
      QStringLiteral("FontAwesome-Brands.otf")};
  BundledFonts result;
  int loadedFonts = 0;
  for (const QString &fontFile : fontFiles) {
    const QString path = fontsDirectory.filePath(fontFile);
    const int fontId = QFontDatabase::addApplicationFont(path);
    if (fontId < 0) {
      qWarning().noquote() << "Zui could not register bundled font:" << path;
      continue;
    }
    ++loadedFonts;
    const QStringList families = QFontDatabase::applicationFontFamilies(fontId);
    if (families.isEmpty())
      continue;
    if (result.textFamily.isEmpty() && fontFile.startsWith(QStringLiteral("RobotoMono")))
      result.textFamily = families.first();
    else if (fontFile == QStringLiteral("FontAwesome-Solid.otf"))
      result.iconFamily = families.first();
    else if (fontFile == QStringLiteral("FontAwesome-Brands.otf"))
      result.brandIconFamily = families.first();
  }
  result.ready = loadedFonts == fontFiles.size() && !result.textFamily.isEmpty()
      && !result.iconFamily.isEmpty() && !result.brandIconFamily.isEmpty();
  if (result.textFamily.isEmpty())
    return result;

  QFont::insertSubstitution(QStringLiteral("RobotoMono"), result.textFamily);
  QFont::insertSubstitution(QStringLiteral("Roboto Mono"), result.textFamily);
  QGuiApplication::setFont(QFont(result.textFamily));
  return result;
}

void scheduleAllocatorPressureRelief(QObject *context) {
#if defined(Q_OS_DARWIN)
  const auto relieve = [] { malloc_zone_pressure_relief(nullptr, 0); };
  QTimer::singleShot(2500, context, relieve);
  QTimer::singleShot(8000, context, relieve);
#else
  Q_UNUSED(context);
#endif
}
}

int main(int argc, char *argv[]) {
#if defined(ZUI_EMBEDDED_RUNTIME)
  QElapsedTimer startupTimer;
  startupTimer.start();
#endif
#if defined(ZUI_USES_VIRTUAL_KEYBOARD)
  qputenv("QT_IM_MODULE", QByteArrayLiteral("qtvirtualkeyboard"));
#endif
#if defined(ZUI_USES_WEBVIEW)
  QtWebView::initialize();
#endif
  QGuiApplication application(argc, argv);
  QCoreApplication::setApplicationName(QStringLiteral("Zui"));
  QCoreApplication::setOrganizationName(QStringLiteral("Zui"));
#if defined(ZUI_EMBEDDED_RUNTIME)
  const QString qmlCache = QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation))
                               .filePath(QStringLiteral("qmlcache/%1")
                                             .arg(QStringLiteral(ZUI_QML_CACHE_IDENTITY)));
  QDir().mkpath(qmlCache);
  qputenv("QML_DISK_CACHE_PATH", QDir::toNativeSeparators(qmlCache).toUtf8());

  // Qt creates its platform window before the QML engine has parsed the real
  // application window. Keep that interval branded instead of exposing the
  // platform's default black backing surface.
  QQuickWindow startupWindow;
  startupWindow.setColor(QColor(QStringLiteral("#0b1118")));
  startupWindow.showFullScreen();
  QCoreApplication::processEvents();
#endif
  const QByteArray configuredStyle = qgetenv("ZUI_QT_STYLE");
  QQuickStyle::setStyle(configuredStyle.isEmpty()
                           ? QStringLiteral("Fusion")
                           : QString::fromUtf8(configuredStyle));

#if defined(ZUI_EMBEDDED_RUNTIME)
  const QString qmlRoot = QStringLiteral(":/zui");
  const QString qmlImportRoot = QStringLiteral("qrc:/zui");
  const QString project = QStringLiteral("qrc:/app");
#if defined(ZUI_EMBEDDED_CRUBY)
  const QString program = QStringLiteral(":/app/app.rb");
#else
  const QString program = QStringLiteral(":/app/app.mrb");
#endif
  const QString runtimeExecutable;
  const QString rubyLoadPath;
  const QString applicationName = QStringLiteral(ZUI_MOBILE_APP_NAME);
#else
  QCommandLineParser parser;
  parser.setApplicationDescription(QStringLiteral("Zui cross-platform Qt host"));
  parser.addHelpOption();
  parser.addOption({QStringLiteral("qml-root"), QStringLiteral("Zui QML runtime directory"), QStringLiteral("path")});
  parser.addOption({QStringLiteral("project"), QStringLiteral("Application project directory"), QStringLiteral("path")});
  parser.addOption({QStringLiteral("program"), QStringLiteral("Ruby application entrypoint"), QStringLiteral("path")});
  parser.addOption({QStringLiteral("ruby"), QStringLiteral("Ruby executable"), QStringLiteral("path"), QStringLiteral("ruby")});
  parser.addOption({QStringLiteral("load-path"), QStringLiteral("Ruby framework load path"), QStringLiteral("path")});
  parser.addOption({QStringLiteral("name"), QStringLiteral("Application name"), QStringLiteral("name"), QStringLiteral("Zui Application")});
  parser.process(application);

  const QString qmlRootValue = parser.value(QStringLiteral("qml-root"));
  const QString projectValue = parser.value(QStringLiteral("project"));
  const QString programValue = parser.value(QStringLiteral("program"));
  const QString qmlRoot = QFileInfo(qmlRootValue).absoluteFilePath();
  const QString qmlImportRoot = qmlRoot;
  const QString project = QFileInfo(projectValue).absoluteFilePath();
  const QString program = QFileInfo(programValue).absoluteFilePath();
  const QFileInfo desktopFile(QDir(qmlRoot).filePath(QStringLiteral("Desktop.qml")));
  if (qmlRootValue.isEmpty() || projectValue.isEmpty() || programValue.isEmpty()
      || !desktopFile.isFile() || !QFileInfo(project).isDir() || !QFileInfo(program).isFile())
    parser.showHelp(64);
  const QString runtimeExecutable = parser.value(QStringLiteral("ruby"));
  const QString rubyLoadPath = parser.value(QStringLiteral("load-path"));
  const QString applicationName = parser.value(QStringLiteral("name"));
#endif

  const BundledFonts bundledFonts = installBundledFonts(qmlRoot);
#if defined(ZUI_EMBEDDED_RUNTIME)
  qInfo().noquote() << "Zui startup: fonts registered in" << startupTimer.elapsed() << "ms";
#endif

  ZuiRuntimeTransport process;
  ZuiClipboard clipboard;
  ZuiSafeArea safeArea;
  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty(QStringLiteral("zuiProcess"), &process);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiClipboard"), &clipboard);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiSafeArea"), &safeArea);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiProjectDir"), project);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiComponentDir"), QDir(qmlRoot).filePath(QStringLiteral("Components/Builtins")));
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyExecutable"), runtimeExecutable);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyProgram"), program);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyLoadPath"), rubyLoadPath);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiApplicationName"), applicationName);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiBundledFontsReady"), bundledFonts.ready);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiBundledTextFont"), bundledFonts.textFamily);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiBundledIconFont"), bundledFonts.iconFamily);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiBundledBrandIconFont"), bundledFonts.brandIconFamily);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiMobile"),
#if defined(ZUI_EMBEDDED_RUNTIME)
                                            true
#else
                                            false
#endif
  );
  engine.addImportPath(qmlImportRoot);

  QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &application,
                   [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
#if defined(ZUI_EMBEDDED_RUNTIME)
  QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &startupWindow,
                   [&startupWindow, &startupTimer](QObject *object, const QUrl &) {
    auto *window = qobject_cast<QQuickWindow *>(object);
    if (!window)
      return;
    QObject::connect(window, &QQuickWindow::frameSwapped, &startupWindow,
                     [&startupWindow, &startupTimer] {
      qInfo().noquote() << "Zui startup: first frame visible in"
                        << startupTimer.elapsed() << "ms";
      startupWindow.hide();
      startupWindow.destroy();
    }, Qt::SingleShotConnection);
    window->requestUpdate();
  });
  engine.load(QUrl(QStringLiteral("qrc:/zui/Desktop.qml")));
#else
  engine.load(QUrl::fromLocalFile(QDir(qmlRoot).filePath(QStringLiteral("Desktop.qml"))));
#endif
#if defined(ZUI_EMBEDDED_RUNTIME)
  qInfo().noquote() << "Zui startup: interface loaded in" << startupTimer.elapsed() << "ms";
#endif
  scheduleAllocatorPressureRelief(&application);
  return application.exec();
}
