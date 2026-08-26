#pragma once

#include <QObject>
#include <QString>

struct mrb_state;

class ZuiEmbeddedRuntime final : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
  explicit ZuiEmbeddedRuntime(QObject *parent = nullptr);
  ~ZuiEmbeddedRuntime() override;

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
  bool loadProgram(const QString &program);
  bool callZui(const char *method, const QString *argument = nullptr);
  QString exceptionMessage() const;
  void finish(int exitCode);

  mrb_state *m_state = nullptr;
  bool m_running = false;
};
