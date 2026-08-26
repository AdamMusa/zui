#include "ZuiSafeArea.h"

#include <QGuiApplication>
#include <QTimer>

#import <UIKit/UIKit.h>

ZuiSafeArea::ZuiSafeArea(QObject *parent) : QObject(parent) {
  auto *timer = new QTimer(this);
  timer->setInterval(250);
  connect(timer, &QTimer::timeout, this, &ZuiSafeArea::refresh);
  connect(qGuiApp, &QGuiApplication::applicationStateChanged, this,
          [this] { QTimer::singleShot(0, this, &ZuiSafeArea::refresh); });
  timer->start();
  QTimer::singleShot(0, this, &ZuiSafeArea::refresh);
}

void ZuiSafeArea::refresh() {
  UIWindow *window = nil;
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if (![scene isKindOfClass:UIWindowScene.class])
      continue;
    for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
      if (candidate.isKeyWindow) {
        window = candidate;
        break;
      }
      if (!window && !candidate.hidden)
        window = candidate;
    }
    if (window)
      break;
  }
  if (!window)
    return;

  const UIEdgeInsets insets = window.safeAreaInsets;
  update(insets.left, insets.top, insets.right, insets.bottom);
}

void ZuiSafeArea::update(qreal left, qreal top, qreal right, qreal bottom) {
  if (qFuzzyCompare(m_left + 1, left + 1) && qFuzzyCompare(m_top + 1, top + 1)
      && qFuzzyCompare(m_right + 1, right + 1) && qFuzzyCompare(m_bottom + 1, bottom + 1))
    return;
  m_left = left;
  m_top = top;
  m_right = right;
  m_bottom = bottom;
  emit changed();
}
