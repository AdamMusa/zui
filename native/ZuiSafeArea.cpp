#include "ZuiSafeArea.h"

ZuiSafeArea::ZuiSafeArea(QObject *parent) : QObject(parent) {}

void ZuiSafeArea::refresh() {}

void ZuiSafeArea::update(qreal left, qreal top, qreal right, qreal bottom) {
  if (m_left == left && m_top == top && m_right == right && m_bottom == bottom)
    return;
  m_left = left;
  m_top = top;
  m_right = right;
  m_bottom = bottom;
  emit changed();
}
