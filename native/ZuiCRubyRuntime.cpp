#include "ZuiCRubyRuntime.h"

#include <QDebug>
#include <QElapsedTimer>
#include <QFile>
#include <QMetaObject>

#include <ruby.h>

extern "C" void Init_json_ext_generator();
extern "C" void Init_json_ext_parser();
extern "C" void Init_encdb();
extern "C" void ruby_init_ext(const char *name, void (*initializer)());

extern "C" void Init_enc() {
  Init_encdb();
  rb_provide("encdb.so");
}

extern "C" void Init_ext() {
  ruby_init_ext("json/ext/generator.so", Init_json_ext_generator);
  ruby_init_ext("json/ext/parser.so", Init_json_ext_parser);
}

namespace {
ZuiCRubyRuntime *activeRuntime = nullptr;

VALUE emitLine(VALUE, VALUE value) {
  StringValue(value);
  if (activeRuntime) {
    activeRuntime->publishLine(
        QString::fromUtf8(RSTRING_PTR(value), static_cast<qsizetype>(RSTRING_LEN(value))));
  }
  return Qnil;
}

VALUE emitError(VALUE, VALUE value) {
  StringValue(value);
  if (activeRuntime) {
    activeRuntime->publishError(
        QString::fromUtf8(RSTRING_PTR(value), static_cast<qsizetype>(RSTRING_LEN(value))));
  }
  return Qnil;
}

struct ProtectedCall {
  VALUE receiver;
  ID method;
  VALUE argument;
  bool hasArgument;
};

VALUE invokeProtected(VALUE opaque) {
  auto *call = reinterpret_cast<ProtectedCall *>(opaque);
  return call->hasArgument
      ? rb_funcall(call->receiver, call->method, 1, call->argument)
      : rb_funcall(call->receiver, call->method, 0);
}

VALUE fullExceptionMessage(VALUE exception) {
  return rb_funcall(exception, rb_intern("full_message"), 0);
}
}

ZuiCRubyRuntime::ZuiCRubyRuntime(QObject *parent) : QObject(parent) {}

ZuiCRubyRuntime::~ZuiCRubyRuntime() {
  stop();
  if (m_initialized) {
    ruby_cleanup(0);
    m_initialized = false;
  }
}

bool ZuiCRubyRuntime::running() const { return m_running; }

void ZuiCRubyRuntime::start(const QString &, const QString &program,
                            const QString &, const QString &) {
  if (m_running || m_initialized || program.isEmpty())
    return;

  QElapsedTimer timer;
  timer.start();
  RUBY_INIT_STACK;
  if (ruby_setup() != 0) {
    publishError(QStringLiteral("Unable to initialize the embedded CRuby runtime"));
    finish(1);
    return;
  }

  m_initialized = true;
  activeRuntime = this;
  char executable[] = "zui-mobile";
  char disableGems[] = "--disable-gems";
  char evaluate[] = "-e";
  char emptyProgram[] = "";
  char *arguments[] = {executable, disableGems, evaluate, emptyProgram, nullptr};
  ruby_options(4, arguments);
  ruby_script("zui-mobile");
  VALUE bridge = rb_define_module("ZuiNative");
  rb_define_module_function(bridge, "emit", RUBY_METHOD_FUNC(emitLine), 1);
  rb_define_module_function(bridge, "emit_error", RUBY_METHOD_FUNC(emitError), 1);

  m_running = true;
  emit runningChanged();
  if (!loadCRubySupport() || !loadProgram(program))
    finish(1);
  else
    qInfo().noquote() << "Zui startup: embedded CRuby ready in" << timer.elapsed() << "ms";
}

void ZuiCRubyRuntime::write(const QString &data) {
  if (!m_running || !m_initialized)
    return;
  if (!callZui("embedded_receive", &data))
    finish(1);
}

void ZuiCRubyRuntime::stop() {
  if (!m_initialized && !m_running)
    return;
  if (m_initialized && m_running)
    callZui("embedded_stop");
  finish(0);
}

void ZuiCRubyRuntime::publishLine(const QString &line) {
  QMetaObject::invokeMethod(this, [this, line] { emit lineReceived(line); },
                            Qt::QueuedConnection);
}

void ZuiCRubyRuntime::publishError(const QString &line) {
  QMetaObject::invokeMethod(this, [this, line] { emit errorLineReceived(line); },
                            Qt::QueuedConnection);
}

bool ZuiCRubyRuntime::loadProgram(const QString &program) {
  return loadSource(program);
}

bool ZuiCRubyRuntime::loadCRubySupport() {
  if (!loadSource(QStringLiteral(":/app/cruby/json/version.rb")))
    return false;
  rb_provide("json/version.rb");
  if (!loadSource(QStringLiteral(":/app/cruby/json/common.rb")))
    return false;
  rb_provide("json/common.rb");
  if (!loadSource(QStringLiteral(":/app/cruby/json/ext/generator/state.rb")))
    return false;
  rb_provide("json/ext/generator/state.rb");
  if (!loadSource(QStringLiteral(":/app/cruby/json/ext.rb")))
    return false;
  rb_provide("json.rb");
  return true;
}

bool ZuiCRubyRuntime::loadSource(const QString &program) {
  QFile source(program);
  if (!source.open(QIODevice::ReadOnly)) {
    publishError(QStringLiteral("Unable to open embedded Ruby application: %1").arg(program));
    return false;
  }

  QByteArray bytes("# encoding: UTF-8\n");
  bytes.append(source.readAll());
  bytes.append('\0');
  int state = 0;
  rb_eval_string_protect(bytes.constData(), &state);
  if (state == 0)
    return true;

  publishError(exceptionMessage());
  return false;
}

bool ZuiCRubyRuntime::callZui(const char *method, const QString *argument) {
  const ID zuiId = rb_intern("Zui");
  if (!rb_const_defined(rb_cObject, zuiId)) {
    publishError(QStringLiteral("Embedded Ruby application did not define Zui"));
    return false;
  }

  ProtectedCall call{rb_const_get(rb_cObject, zuiId), rb_intern(method), Qnil, false};
  QByteArray bytes;
  if (argument) {
    bytes = argument->toUtf8();
    call.argument = rb_utf8_str_new(bytes.constData(), static_cast<long>(bytes.size()));
    call.hasArgument = true;
  }
  int state = 0;
  rb_protect(invokeProtected, reinterpret_cast<VALUE>(&call), &state);
  if (state == 0)
    return true;

  publishError(exceptionMessage());
  return false;
}

QString ZuiCRubyRuntime::exceptionMessage() {
  VALUE exception = rb_errinfo();
  if (NIL_P(exception))
    return QStringLiteral("Unknown embedded CRuby runtime error");

  int state = 0;
  VALUE inspected = rb_protect(fullExceptionMessage, exception, &state);
  if (state != 0)
    inspected = rb_inspect(exception);
  StringValue(inspected);
  const QString result = QString::fromUtf8(
      RSTRING_PTR(inspected), static_cast<qsizetype>(RSTRING_LEN(inspected)));
  rb_set_errinfo(Qnil);
  return result;
}

void ZuiCRubyRuntime::finish(int exitCode) {
  const bool wasRunning = m_running;
  m_running = false;
  if (activeRuntime == this)
    activeRuntime = nullptr;
  if (wasRunning)
    emit runningChanged();
  QMetaObject::invokeMethod(this, [this, exitCode] { emit exited(exitCode); },
                            Qt::QueuedConnection);
}
