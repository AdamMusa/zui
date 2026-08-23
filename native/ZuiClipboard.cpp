#include "ZuiClipboard.h"

#include <QGuiApplication>
#include <QClipboard>

ZuiClipboard::ZuiClipboard(QObject *parent) : QObject(parent) {
  connect(QGuiApplication::clipboard(), &QClipboard::dataChanged, this, &ZuiClipboard::textChanged);
}

QString ZuiClipboard::text() const { return QGuiApplication::clipboard()->text(); }

void ZuiClipboard::setText(const QString &text) {
  if (this->text() == text)
    return;
  QGuiApplication::clipboard()->setText(text);
}
