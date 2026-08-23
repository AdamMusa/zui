import QtQuick

FocusScope {
  id: root
  property bool blocked: false
  signal closeRequested()
  signal deleteRequested()
  signal returnRequested()
  signal tabRequested(bool reverse)
  signal moveRequested(int dx, int dy)
  signal activateRequested()
  signal textKey(string text)
  focus: true
  Keys.onEscapePressed: if (!blocked) closeRequested()
  Keys.onDeletePressed: if (!blocked) deleteRequested()
  Keys.onReturnPressed: if (!blocked) returnRequested()
  Keys.onTabPressed: if (!blocked) tabRequested(false)
  Keys.onBacktabPressed: if (!blocked) tabRequested(true)
  Keys.onLeftPressed: if (!blocked) moveRequested(-1, 0)
  Keys.onRightPressed: if (!blocked) moveRequested(1, 0)
  Keys.onUpPressed: if (!blocked) moveRequested(0, -1)
  Keys.onDownPressed: if (!blocked) moveRequested(0, 1)
  Keys.onSpacePressed: if (!blocked) activateRequested()
  Keys.onPressed: function(event) { if (!blocked && event.text !== "") root.textKey(event.text) }
}
