#pragma once

#include <QObject>
#include <QProcess>

class ZuiProcess final : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
  explicit ZuiProcess(QObject *parent = nullptr);
  ~ZuiProcess() override;

  bool running() const;

  Q_INVOKABLE void start(const QString &executable, const QString &program,
                         const QString &workingDirectory, const QString &loadPath);
  Q_INVOKABLE void write(const QString &data);
  Q_INVOKABLE void stop();

signals:
  void runningChanged();
  void lineReceived(const QString &line);
  void errorLineReceived(const QString &line);
  void exited(int exitCode);

private:
  void consume(QByteArray &buffer, bool errorStream);
  void flush(QByteArray &buffer, bool errorStream);

  QProcess m_process;
  QByteArray m_stdoutBuffer;
  QByteArray m_stderrBuffer;
};
