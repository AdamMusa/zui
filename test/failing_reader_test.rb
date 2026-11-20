# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../lib/zui"

# A reader or renderer that raises while state changes must not cost the rest
# of the interface its update.
class FailingReaderTest < Minitest::Test
  def started(app)
    output = StringIO.new
    app.start(output:, error: StringIO.new)
    output.truncate(0)
    output.rewind
    output
  end

  def patches(output)
    output.string.lines.map { |line| JSON.parse(line) }.select { |message| message["type"] == "patch" }
  end

  def set_values(output)
    patches(output).flat_map { |patch| patch["op"] == "batch" ? patch["patches"] : [patch] }
                   .select { |patch| patch["op"] == "set" }
                   .to_h { |patch| [patch["id"], patch["value"]] }
  end

  def test_a_binding_that_raises_does_not_swallow_the_patches_of_the_others
    app = Zui::Application.new do
      state :n, 0
      panel :main do
        before = text "", id: :before
        broken = text "", id: :broken
        after = text "", id: :after
        bind(before, :text) { "before=#{state.n}" }
        bind(broken, :text) { raise "boom" if state.n == 1; "broken=#{state.n}" }
        bind(after, :text) { "after=#{state.n}" }
      end
    end
    output = started(app)

    error = assert_raises(RuntimeError) { app.state.n = 1 }

    assert_equal "boom", error.message
    assert_equal({ "before" => "before=1", "after" => "after=1" }, set_values(output))
  end

  def test_a_failing_binding_recovers_on_the_next_change
    app = Zui::Application.new do
      state :n, 0
      panel :main do
        broken = text "", id: :broken
        bind(broken, :text) { raise "boom" if state.n == 1; "broken=#{state.n}" }
      end
    end
    output = started(app)
    assert_raises(RuntimeError) { app.state.n = 1 }

    app.state.n = 2

    assert_equal({ "broken" => "broken=2" }, set_values(output))
  end

  def test_a_renderer_that_raises_does_not_stop_the_bindings_after_it
    app = Zui::Application.new do
      state :n, 0
      panel :main do
        dynamic(id: :list) do
          raise "renderer boom" if state.n == 1

          text "row #{state.n}"
        end
        status = text "", id: :status
        bind(status, :text) { "n=#{state.n}" }
      end
    end
    output = started(app)

    error = assert_raises(RuntimeError) { app.state.n = 1 }

    assert_equal "renderer boom", error.message
    assert_equal({ "status" => "n=1" }, set_values(output))
  end

  def test_the_first_failure_is_the_one_raised
    app = Zui::Application.new do
      state :n, 0
      panel :main do
        first = text "", id: :first
        second = text "", id: :second
        bind(first, :text) { raise "first" if state.n == 1; "ok" }
        bind(second, :text) { raise "second" if state.n == 1; "ok" }
      end
    end
    started(app)

    assert_equal "first", assert_raises(RuntimeError) { app.state.n = 1 }.message
  end
end
