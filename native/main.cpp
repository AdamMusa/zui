#include "ZuiClipboard.h"

#if defined(ZUI_EMBEDDED_RUNTIME)
#include "ZuiEmbeddedRuntime.h"
using ZuiRuntimeTransport = ZuiEmbeddedRuntime;
#else
#include "ZuiProcess.h"
using ZuiRuntimeTransport = ZuiProcess;
#endif

#include <QCommandLineParser>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

namespace {
void installBundledFonts(const QString &qmlRoot) {
  const QDir fontsDirectory(QDir(qmlRoot).filePath(QStringLiteral("Fonts")));
  const QStringList fontFiles = {
      QStringLiteral("RobotoMono-Regular.otf"),
      QStringLiteral("RobotoMono-Bold.otf"),
      QStringLiteral("FontAwesome-Solid.otf"),
      QStringLiteral("FontAwesome-Brands.otf")};
  QString textFamily;
  for (const QString &fontFile : fontFiles) {
    const QString path = fontsDirectory.filePath(fontFile);
    const int fontId = QFontDatabase::addApplicationFont(path);
    if (fontId < 0) {
      qWarning().noquote() << "Zui could not register bundled font:" << path;
      continue;
    }
    const QStringList families = QFontDatabase::applicationFontFamilies(fontId);
    if (textFamily.isEmpty() && fontFile.startsWith(QStringLiteral("RobotoMono"))
        && !families.isEmpty())
      textFamily = families.first();
  }
  if (textFamily.isEmpty())
    return;

  QFont::insertSubstitution(QStringLiteral("RobotoMono"), textFamily);
  QFont::insertSubstitution(QStringLiteral("Roboto Mono"), textFamily);
  QGuiApplication::setFont(QFont(textFamily));
}
}

int main(int argc, char *argv[]) {
  QGuiApplication application(argc, argv);
  QCoreApplication::setApplicationName(QStringLiteral("Zui"));
  QCoreApplication::setOrganizationName(QStringLiteral("Zui"));
  QQuickStyle::setStyle(QStringLiteral("Fusion"));

#if defined(ZUI_EMBEDDED_RUNTIME)
  const QString qmlRoot = QStringLiteral(":/zui");
  const QString qmlImportRoot = QStringLiteral("qrc:/zui");
  const QString project = QStringLiteral("qrc:/app");
  const QString program = QStringLiteral(":/app/app.rb");
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

  installBundledFonts(qmlRoot);

  ZuiRuntimeTransport process;
  ZuiClipboard clipboard;
  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty(QStringLiteral("zuiProcess"), &process);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiClipboard"), &clipboard);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiProjectDir"), project);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiComponentDir"), QDir(qmlRoot).filePath(QStringLiteral("Components/Builtins")));
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyExecutable"), runtimeExecutable);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyProgram"), program);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyLoadPath"), rubyLoadPath);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiApplicationName"), applicationName);
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
  engine.load(QUrl(QStringLiteral("qrc:/zui/Desktop.qml")));
#else
  engine.load(QUrl::fromLocalFile(QDir(qmlRoot).filePath(QStringLiteral("Desktop.qml"))));
#endif
  return application.exec();
}
