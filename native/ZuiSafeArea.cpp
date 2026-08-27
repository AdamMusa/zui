#include "ZuiSafeArea.h"

#if defined(Q_OS_ANDROID)
#include <QDeadlineTimer>
#include <QGuiApplication>
#include <QJniObject>
#include <QtCore/qcoreapplication_platform.h>
#include <QScreen>
#include <QTimer>
#include <QVariantList>
#endif

ZuiSafeArea::ZuiSafeArea(QObject *parent) : QObject(parent) {
#if defined(Q_OS_ANDROID)
  auto *timer = new QTimer(this);
  timer->setInterval(1000);
  connect(timer, &QTimer::timeout, this, &ZuiSafeArea::refresh);
  connect(qGuiApp, &QGuiApplication::applicationStateChanged, this,
          [this] { QTimer::singleShot(0, this, &ZuiSafeArea::refresh); });
  timer->start();
  QTimer::singleShot(0, this, &ZuiSafeArea::refresh);
#endif
}

void ZuiSafeArea::refresh() {
#if defined(Q_OS_ANDROID)
  if (m_refreshPending)
    return;
  m_refreshPending = true;
  auto future = QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() -> QVariant {
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative", "activity", "()Landroid/app/Activity;");
    if (!activity.isValid())
      return QVariantList{};
    QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
    QJniObject decor = window.callObjectMethod("getDecorView", "()Landroid/view/View;");
    QJniObject insets = decor.callObjectMethod("getRootWindowInsets", "()Landroid/view/WindowInsets;");
    if (!insets.isValid())
      return QVariantList{};

    jint left = 0;
    jint top = 0;
    jint right = 0;
    jint bottom = 0;
    if (QNativeInterface::QAndroidApplication::sdkVersion() >= 30) {
      const jint systemBars = QJniObject::callStaticMethod<jint>(
          "android/view/WindowInsets$Type", "systemBars", "()I");
      const jint displayCutout = QJniObject::callStaticMethod<jint>(
          "android/view/WindowInsets$Type", "displayCutout", "()I");
      QJniObject safe = insets.callObjectMethod(
          "getInsets", "(I)Landroid/graphics/Insets;", systemBars | displayCutout);
      left = safe.getField<jint>("left");
      top = safe.getField<jint>("top");
      right = safe.getField<jint>("right");
      bottom = safe.getField<jint>("bottom");
    } else {
      left = insets.callMethod<jint>("getSystemWindowInsetLeft", "()I");
      top = insets.callMethod<jint>("getSystemWindowInsetTop", "()I");
      right = insets.callMethod<jint>("getSystemWindowInsetRight", "()I");
      bottom = insets.callMethod<jint>("getSystemWindowInsetBottom", "()I");
    }
    return QVariantList{left, top, right, bottom};
  }, QDeadlineTimer(1000));
  future.then(this, [this](const QVariant &result) {
    m_refreshPending = false;
    const QVariantList values = result.toList();
    if (values.size() != 4)
      return;
    const QScreen *screen = QGuiApplication::primaryScreen();
    const qreal scale = screen ? qMax<qreal>(1, screen->devicePixelRatio()) : 1;
    update(values[0].toReal() / scale, values[1].toReal() / scale,
           values[2].toReal() / scale, values[3].toReal() / scale);
  });
#endif
}

void ZuiSafeArea::update(qreal left, qreal top, qreal right, qreal bottom) {
  if (m_left == left && m_top == top && m_right == right && m_bottom == bottom)
    return;
  m_left = left;
  m_top = top;
  m_right = right;
  m_bottom = bottom;
  emit changed();
}
