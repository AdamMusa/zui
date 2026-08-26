# frozen_string_literal: true

require "json"
require "minitest/autorun"
require_relative "../lib/zui"
require_relative "../lib/zui/lite_entry"

class EmbeddedRuntimeTest < Minitest::Test
  def test_direct_application_run_uses_the_embedded_transport
    lines = []
    errors = []
    bridge = Module.new
    bridge.define_singleton_method(:emit) { |line| lines << line }
    bridge.define_singleton_method(:emit_error) { |line| errors << line }
    Object.const_set(:ZuiNative, bridge)

    application = Zui::Application.new do
      state :count, 0
      app :main do
        value = text "0", id: :count
        bind(value, :text) { state.count.to_s }
        button "Tap", id: :tap do
          state.count += 1
        end
      end
    end

    assert_same application, application.run
    assert_equal %w[ready render], lines.map { |line| JSON.parse(line).fetch("type") }

    Zui.embedded_receive(JSON.generate(
      "v" => 1, "type" => "event", "surface" => "main", "id" => "tap",
      "event" => "click", "seq" => 1, "payload" => {}
    ))

    messages = lines.map { |line| JSON.parse(line) }
    assert_equal "patch", messages.fetch(2).fetch("type")
    assert_equal "1", messages.fetch(2).fetch("value")
    assert_equal "ack", messages.fetch(3).fetch("type")
    assert_empty errors
  ensure
    Zui.embedded_stop
    Object.send(:remove_const, :ZuiNative) if Object.const_defined?(:ZuiNative)
  end
end
