import QtQuick
import "../Theme"

Dropdown {
  property string placeholderText: "Search..."
  property string emptyText: "No matches"
  property string triggerLabel: ""
  property color popupBorder: Color.popups.border
  property real popupRowHeight: Style.spacing.popupRowHeight
  property real popupMinHeight: Style.spacing.searchablePopupMinHeight
}
