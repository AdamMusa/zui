# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class QmlTeardownHandlersTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def read(name)
    File.read(File.join(ROOT, name), encoding: "UTF-8")
  end

  def sources(glob)
    Dir[File.join(ROOT, glob)].sort.to_h do |path|
      [path.delete_prefix("#{ROOT}/"), File.read(path, encoding: "UTF-8")]
    end
  end

  # Handlers that answer something the user did run while the node is alive.
  # Every other handler can also run while the node is being torn down: a page
  # replacement hides each control on the way out (`visible` -> false), drops
  # its focus and hover, closes its popups and cancels its pointer handlers,
  # and by then `renderer` -- a required property bound to the ControlNode --
  # has already gone undefined. `renderer.bridge` then throws, once per
  # control, on every page switch ("Cannot read property 'bridge' of
  # undefined" from thirteen adapters on the showcase's Navigation page alone).
  # ItemDelegate guards itself; this holds every adapter to the same rule.
  GESTURE_HANDLERS = %w[
    Tapped Clicked DoubleClicked DoubleTapped Pressed Released Toggled Accepted
    Moved TextEdited EditingFinished Modified LinkActivated PressAndHold
    Activated Triggered Confirmed Changed Hovered RightClicked
  ].freeze

  def test_lifecycle_handlers_check_their_node_before_posting
    offenders = []
    sources("Components/Builtins/**/*.qml").merge(sources("Controls/*.qml")).each do |name, qml|
      qml.each_line.with_index(1) do |line, number|
        next unless (match = line.match(/\bon([A-Z]\w*):\s*(?:root\.)?renderer\.bridge\.sendEvent/))
        next if GESTURE_HANDLERS.include?(match[1])

        offenders << "#{name}:#{number} on#{match[1]}"
      end
    end

    assert_empty offenders,
                 "these handlers can run during teardown and call the bridge without " \
                 "checking `renderer` first: #{offenders.inspect}"
  end
end
