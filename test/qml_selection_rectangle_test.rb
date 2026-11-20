# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class QmlSelectionRectangleTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def read(name)
    File.read(File.join(ROOT, name), encoding: "UTF-8")
  end

  def sources(glob)
    Dir[File.join(ROOT, glob)].sort.to_h do |path|
      [path.delete_prefix("#{ROOT}/"), File.read(path, encoding: "UTF-8")]
    end
  end

  # SelectionRectangle only accepts a view that implements Qt's selectable
  # interface. The node it is pointed at renders as the adapter around the view,
  # so the view is handed over explicitly or Qt answers "the assigned target is
  # not supported by the control" and the rubber band never works.
  def test_selection_rectangle_attaches_to_the_view_inside_its_target
    rectangle = read("Components/Builtins/SelectionRectangle.qml")
    table = read("Components/Builtins/TableView.qml")

    assert_includes rectangle, "target: selectableTarget()"
    assert_includes rectangle, "found.selectableView"
    assert_includes table, "readonly property var selectableView: tableControl"
  end
end
