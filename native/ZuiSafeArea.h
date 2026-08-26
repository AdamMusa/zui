#pragma once

#include <QObject>

class ZuiSafeArea final : public QObject {
  Q_OBJECT
  Q_PROPERTY(qreal left READ left NOTIFY changed)
  Q_PROPERTY(qreal top READ top NOTIFY changed)
  Q_PROPERTY(qreal right READ right NOTIFY changed)
  Q_PROPERTY(qreal bottom READ bottom NOTIFY changed)

public:
  explicit ZuiSafeArea(QObject *parent = nullptr);

  qreal left() const { return m_left; }
  qreal top() const { return m_top; }
  qreal right() const { return m_right; }
  qreal bottom() const { return m_bottom; }

signals:
  void changed();

private:
  void refresh();
  void update(qreal left, qreal top, qreal right, qreal bottom);

  qreal m_left = 0;
  qreal m_top = 0;
  qreal m_right = 0;
  qreal m_bottom = 0;
};
