import QtQuick

Item {
  id: accessibleRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", accessibleContent.implicitWidth))
  implicitHeight: Number(renderer.prop("height", accessibleContent.implicitHeight))

  function role() {
    var requested = String(renderer.prop("role", "none"))
    if (requested === "button") return Accessible.Button
    if (requested === "check_box") return Accessible.CheckBox
    if (requested === "radio_button") return Accessible.RadioButton
    if (requested === "combo_box") return Accessible.ComboBox
    if (requested === "slider") return Accessible.Slider
    if (requested === "spin_box") return Accessible.SpinBox
    if (requested === "progress_bar") return Accessible.ProgressBar
    if (requested === "dial") return Accessible.Dial
    if (requested === "static_text") return Accessible.StaticText
    if (requested === "editable_text") return Accessible.EditableText
    if (requested === "link") return Accessible.Link
    if (requested === "list") return Accessible.List
    if (requested === "list_item") return Accessible.ListItem
    if (requested === "tree") return Accessible.Tree
    if (requested === "tree_item") return Accessible.TreeItem
    if (requested === "table") return Accessible.Table
    if (requested === "cell") return Accessible.Cell
    if (requested === "row") return Accessible.Row
    if (requested === "column") return Accessible.Column
    if (requested === "row_header") return Accessible.RowHeader
    if (requested === "column_header") return Accessible.ColumnHeader
    if (requested === "dialog") return Accessible.Dialog
    if (requested === "window") return Accessible.Window
    if (requested === "pane") return Accessible.Pane
    if (requested === "grouping") return Accessible.Grouping
    if (requested === "separator") return Accessible.Separator
    if (requested === "tool_bar") return Accessible.ToolBar
    if (requested === "status_bar") return Accessible.StatusBar
    if (requested === "menu_bar") return Accessible.MenuBar
    if (requested === "popup_menu") return Accessible.PopupMenu
    if (requested === "menu_item") return Accessible.MenuItem
    if (requested === "page_tab") return Accessible.PageTab
    if (requested === "page_tab_list") return Accessible.PageTabList
    if (requested === "scroll_bar") return Accessible.ScrollBar
    if (requested === "tool_tip") return Accessible.ToolTip
    if (requested === "graphic") return Accessible.Graphic
    if (requested === "indicator") return Accessible.Indicator
    if (requested === "paragraph") return Accessible.Paragraph
    if (requested === "section") return Accessible.Section
    if (requested === "canvas") return Accessible.Canvas
    if (requested === "clock") return Accessible.Clock
    if (requested === "chart") return Accessible.Chart
    if (requested === "splitter") return Accessible.Splitter
    if (requested === "terminal") return Accessible.Terminal
    return Accessible.NoRole
  }

  function report(name) {
    if (!renderer.subscribed(name)) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, {})
  }

  Item {
    id: accessibleContent
    anchors.fill: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    Accessible.role: accessibleRoot.role()
    Accessible.name: String(renderer.prop("name", ""))
    Accessible.description: String(renderer.prop("description", ""))
    Accessible.ignored: renderer.prop("ignored", false) === true
    Accessible.checkable: renderer.prop("checkable", false) === true
    Accessible.checked: renderer.prop("checked", false) === true
    Accessible.checkStateMixed: renderer.prop("check_state_mixed", false) === true
    Accessible.editable: renderer.prop("editable", false) === true
    Accessible.focusable: renderer.prop("focusable", false) === true
    Accessible.focused: renderer.prop("focused", false) === true
    Accessible.multiLine: renderer.prop("multi_line", false) === true
    Accessible.readOnly: renderer.prop("read_only", false) === true
    Accessible.selected: renderer.prop("selected", false) === true
    Accessible.selectable: renderer.prop("selectable", false) === true
    Accessible.pressed: renderer.prop("pressed", false) === true
    Accessible.defaultButton: renderer.prop("default_button", false) === true
    Accessible.passwordEdit: renderer.prop("password_edit", false) === true
    Accessible.selectableText: renderer.prop("selectable_text", false) === true
    Accessible.searchEdit: renderer.prop("search_edit", false) === true

    Accessible.onPressAction: accessibleRoot.report("press_action")
    Accessible.onToggleAction: accessibleRoot.report("toggle_action")
    Accessible.onIncreaseAction: accessibleRoot.report("increase_action")
    Accessible.onDecreaseAction: accessibleRoot.report("decrease_action")
    Accessible.onScrollUpAction: accessibleRoot.report("scroll_up_action")
    Accessible.onScrollDownAction: accessibleRoot.report("scroll_down_action")
    Accessible.onScrollLeftAction: accessibleRoot.report("scroll_left_action")
    Accessible.onScrollRightAction: accessibleRoot.report("scroll_right_action")
    Accessible.onPreviousPageAction: accessibleRoot.report("previous_page_action")
    Accessible.onNextPageAction: accessibleRoot.report("next_page_action")

    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
