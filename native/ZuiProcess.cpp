#include "ZuiProcess.h"

#include <QProcessEnvironment>
#include <QTimer>

ZuiProcess::ZuiProcess(QObject *parent) : QObject(parent) {
  connect(&m_process, &QProcess::stateChanged, this, [this] { emit runningChanged(); });
  connect(&m_process, &QProcess::readyReadStandardOutput, this, [this] {
    m_stdoutBuffer += m_process.readAllStandardOutput();
    consume(m_stdoutBuffer, false);
  });
  connect(&m_process, &QProcess::readyReadStandardError, this, [this] {
    m_stderrBuffer += m_process.readAllStandardError();
    consume(m_stderrBuffer, true);
  });
  connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError) {
    emit errorLineReceived(m_process.errorString());
  });
  connect(&m_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
          [this](int exitCode, QProcess::ExitStatus exitStatus) {
            if (exitStatus == QProcess::CrashExit)
              m_crashed = true;
            m_stdoutBuffer += m_process.readAllStandardOutput();
            m_stderrBuffer += m_process.readAllStandardError();
            flush(m_stdoutBuffer, false);
            flush(m_stderrBuffer, true);
            emit exited(exitCode);
          });
}

ZuiProcess::~ZuiProcess() { stop(); }

bool ZuiProcess::running() const { return m_process.state() != QProcess::NotRunning; }

void ZuiProcess::start(const QString &executable, const QString &program,
                       const QString &workingDirectory, const QString &loadPath) {
  if (running() || m_crashed || executable.isEmpty() || program.isEmpty())
    return;

  QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
  environment.insert(QStringLiteral("ZUI_PROJECT_DIR"), workingDirectory);
  m_process.setProcessEnvironment(environment);
  m_process.setWorkingDirectory(workingDirectory);
  m_process.setProcessChannelMode(QProcess::SeparateChannels);

  QStringList arguments;
  if (!loadPath.isEmpty())
    arguments << QStringLiteral("-I") << loadPath;
  arguments << program;
  m_process.start(executable, arguments, QIODevice::ReadWrite);
}

void ZuiProcess::write(const QString &data) {
  if (!running())
    return;
  m_process.write(data.toUtf8());
}

void ZuiProcess::stop() {
  if (!running())
    return;
  m_process.closeWriteChannel();
  m_process.terminate();
  if (!m_process.waitForFinished(1000)) {
    m_process.kill();
    m_process.waitForFinished(1000);
  }
}

void ZuiProcess::consume(QByteArray &buffer, bool errorStream) {
  qsizetype newline = -1;
  while ((newline = buffer.indexOf('\n')) >= 0) {
    const QString line = QString::fromUtf8(buffer.left(newline));
    buffer.remove(0, newline + 1);
    errorStream ? emit errorLineReceived(line) : emit lineReceived(line);
  }
}

void ZuiProcess::flush(QByteArray &buffer, bool errorStream) {
  consume(buffer, errorStream);
  if (buffer.isEmpty())
    return;
  const QString line = QString::fromUtf8(buffer);
  buffer.clear();
  errorStream ? emit errorLineReceived(line) : emit lineReceived(line);
}
