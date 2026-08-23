#include "ZuiClipboard.h"
#include "ZuiProcess.h"

#include <QCommandLineParser>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

int main(int argc, char *argv[]) {
  QGuiApplication application(argc, argv);
  QCoreApplication::setApplicationName(QStringLiteral("Zui"));
  QCoreApplication::setOrganizationName(QStringLiteral("Zui"));
  QQuickStyle::setStyle(QStringLiteral("Fusion"));

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

  const QString qmlRoot = QFileInfo(parser.value(QStringLiteral("qml-root"))).absoluteFilePath();
  const QString project = QFileInfo(parser.value(QStringLiteral("project"))).absoluteFilePath();
  const QString program = QFileInfo(parser.value(QStringLiteral("program"))).absoluteFilePath();
  if (!QFileInfo::exists(QDir(qmlRoot).filePath(QStringLiteral("Desktop.qml"))) || !QFileInfo::exists(program))
    parser.showHelp(64);

  ZuiProcess process;
  ZuiClipboard clipboard;
  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty(QStringLiteral("zuiProcess"), &process);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiClipboard"), &clipboard);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiProjectDir"), project);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiComponentDir"), QDir(qmlRoot).filePath(QStringLiteral("Components/Builtins")));
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyExecutable"), parser.value(QStringLiteral("ruby")));
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyProgram"), program);
  engine.rootContext()->setContextProperty(QStringLiteral("zuiRubyLoadPath"), parser.value(QStringLiteral("load-path")));
  engine.rootContext()->setContextProperty(QStringLiteral("zuiApplicationName"), parser.value(QStringLiteral("name")));
  engine.addImportPath(qmlRoot);

  QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &application,
                   [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
  engine.load(QUrl::fromLocalFile(QDir(qmlRoot).filePath(QStringLiteral("Desktop.qml"))));
  return application.exec();
}
