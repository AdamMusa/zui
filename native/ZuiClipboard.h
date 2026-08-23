#pragma once

#include <QObject>

class ZuiClipboard final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)

public:
  explicit ZuiClipboard(QObject *parent = nullptr);
  QString text() const;
  void setText(const QString &text);

signals:
  void textChanged();
};
