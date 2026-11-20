# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class QmlDelegateAnchorsTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def read(name)
    File.read(File.join(ROOT, name), encoding: "UTF-8")
  end

  def sources(glob)
    Dir[File.join(ROOT, glob)].sort.to_h do |path|
      [path.delete_prefix("#{ROOT}/"), File.read(path, encoding: "UTF-8")]
    end
  end

  # The row and column delegates anchor their loader to the parent's edges. A
  # Repeater takes a delegate out of its parent before it destroys it, which
  # re-evaluates every anchor binding with `parent` null, and `parent.top` then
  # throws "Cannot read property 'verticalCenter' of null" -- four on the
  # Buttons page, two on Inputs, and 'left' twice on Navigation.
  def test_row_and_column_delegates_survive_losing_their_parent
    bindings = read("ControlNode.qml").lines.grep(/^\s*anchors\.(?!fill|centerIn)\w+:/)

    refute_empty bindings
    unguarded = bindings.grep(/(?<!\(parent \? )\bparent\.\w+/)
    assert_empty unguarded,
                 "these loader anchors read the parent's edges without checking it exists: #{unguarded.map(&:strip).inspect}"
  end
end
