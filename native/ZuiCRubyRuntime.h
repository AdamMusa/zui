#pragma once

#include <QObject>
#include <QString>

class ZuiCRubyRuntime final : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
  explicit ZuiCRubyRuntime(QObject *parent = nullptr);
  ~ZuiCRubyRuntime() override;

  bool running() const;

  Q_INVOKABLE void start(const QString &executable, const QString &program,
                         const QString &workingDirectory, const QString &loadPath);
  Q_INVOKABLE void write(const QString &data);
  Q_INVOKABLE void stop();

  void publishLine(const QString &line);
  void publishError(const QString &line);

signals:
  void runningChanged();
  void lineReceived(const QString &line);
  void errorLineReceived(const QString &line);
  void exited(int exitCode);

private:
  bool loadCRubySupport();
  bool loadSource(const QString &program);
  bool loadProgram(const QString &program);
  bool callZui(const char *method, const QString *argument = nullptr);
  QString exceptionMessage();
  void finish(int exitCode);

  bool m_initialized = false;
  bool m_running = false;
};
