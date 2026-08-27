#include "ZuiEmbeddedRuntime.h"

#include <QDebug>
#include <QFile>
#include <QElapsedTimer>
#include <QMetaObject>

#include <mruby.h>
#include <mruby/irep.h>
#include <mruby/string.h>

namespace {
ZuiEmbeddedRuntime *runtimeFor(mrb_state *state) {
  return static_cast<ZuiEmbeddedRuntime *>(state->ud);
}

mrb_value emitLine(mrb_state *state, mrb_value) {
  char *value = nullptr;
  mrb_int length = 0;
  mrb_get_args(state, "s", &value, &length);
  if (auto *runtime = runtimeFor(state))
    runtime->publishLine(QString::fromUtf8(value, static_cast<qsizetype>(length)));
  return mrb_nil_value();
}

mrb_value emitError(mrb_state *state, mrb_value) {
  char *value = nullptr;
  mrb_int length = 0;
  mrb_get_args(state, "s", &value, &length);
  if (auto *runtime = runtimeFor(state))
    runtime->publishError(QString::fromUtf8(value, static_cast<qsizetype>(length)));
  return mrb_nil_value();
}
}

ZuiEmbeddedRuntime::ZuiEmbeddedRuntime(QObject *parent) : QObject(parent) {}

ZuiEmbeddedRuntime::~ZuiEmbeddedRuntime() { stop(); }

bool ZuiEmbeddedRuntime::running() const { return m_running.load(); }

void ZuiEmbeddedRuntime::start(const QString &, const QString &program,
                               const QString &, const QString &) {
  if (m_running.load() || program.isEmpty())
    return;

  QElapsedTimer timer;
  timer.start();
  m_state = mrb_open();
  if (!m_state) {
    publishError(QStringLiteral("Unable to initialize the embedded mruby runtime"));
    finish(1);
    return;
  }

  m_state->ud = this;
  struct RClass *bridge = mrb_define_module(m_state, "ZuiNative");
  mrb_define_module_function(m_state, bridge, "emit", emitLine, MRB_ARGS_REQ(1));
  mrb_define_module_function(m_state, bridge, "emit_error", emitError, MRB_ARGS_REQ(1));

  m_running.store(true);
  emit runningChanged();
  if (!loadProgram(program))
    finish(1);
  else
    qInfo().noquote() << "Zui startup: embedded Ruby ready in" << timer.elapsed() << "ms";
}

void ZuiEmbeddedRuntime::write(const QString &data) {
  if (!m_running.load() || !m_state)
    return;
  if (!callZui("embedded_receive", &data))
    finish(1);
}

void ZuiEmbeddedRuntime::stop() {
  if (!m_state && !m_running.load())
    return;
  if (m_state && m_running.load())
    callZui("embedded_stop");
  finish(0);
}

void ZuiEmbeddedRuntime::publishLine(const QString &line) {
  QMetaObject::invokeMethod(this, [this, line] { emit lineReceived(line); },
                            Qt::QueuedConnection);
}

void ZuiEmbeddedRuntime::publishError(const QString &line) {
  QMetaObject::invokeMethod(this, [this, line] { emit errorLineReceived(line); },
                            Qt::QueuedConnection);
}

bool ZuiEmbeddedRuntime::loadProgram(const QString &program) {
  QFile source(program);
  if (!source.open(QIODevice::ReadOnly)) {
    publishError(QStringLiteral("Unable to open embedded Ruby application: %1").arg(program));
    return false;
  }

  const QByteArray bytes = source.readAll();
  mrb_load_irep_buf(m_state, bytes.constData(), static_cast<size_t>(bytes.size()));
  if (!m_state->exc)
    return true;

  publishError(exceptionMessage());
  return false;
}

bool ZuiEmbeddedRuntime::callZui(const char *method, const QString *argument) {
  mrb_value zui = mrb_obj_value(mrb_module_get(m_state, "Zui"));
  if (argument) {
    const QByteArray bytes = argument->toUtf8();
    mrb_value value = mrb_str_new(m_state, bytes.constData(), static_cast<mrb_int>(bytes.size()));
    mrb_funcall(m_state, zui, method, 1, value);
  } else {
    mrb_funcall(m_state, zui, method, 0);
  }
  if (!m_state->exc)
    return true;

  publishError(exceptionMessage());
  return false;
}

QString ZuiEmbeddedRuntime::exceptionMessage() const {
  if (!m_state || !m_state->exc)
    return QStringLiteral("Unknown embedded Ruby runtime error");

  mrb_value exception = mrb_obj_value(m_state->exc);
  mrb_value inspected = mrb_inspect(m_state, exception);
  return QString::fromUtf8(RSTRING_PTR(inspected), static_cast<qsizetype>(RSTRING_LEN(inspected)));
}

void ZuiEmbeddedRuntime::finish(int exitCode) {
  const bool wasRunning = m_running.exchange(false);
  if (m_state) {
    mrb_close(m_state);
    m_state = nullptr;
  }
  if (wasRunning)
    emit runningChanged();
  QMetaObject::invokeMethod(this, [this, exitCode] { emit exited(exitCode); },
                            Qt::QueuedConnection);
}
