# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../lib/zui"

# Which keys a reader read has to survive however the reader reads them.
class StateReadTrackingTest < Minitest::Test
  def started(app)
    output = StringIO.new
    app.start(output:, error: StringIO.new)
    output.truncate(0)
    output.rewind
    output
  end

  def test_keys_read_inside_a_fiber_are_recorded_for_the_binding
    app = Zui::Application.new do
      state :a, 0
      state :b, 0
      panel :main do
        label = text "", id: :summary
        bind(label, :text) do
          lazy_b = Enumerator.new { |yielder| yielder << state.b }
          "a=#{state.a} b=#{lazy_b.next}"
        end
      end
    end
    output = started(app)

    app.state.b = 5

    assert_equal "a=0 b=5", app.tree.fetch("main").fetch("children").first.dig("props", "text")
    assert_includes output.string, "a=0 b=5"
  end

  def test_keys_read_inside_a_fiber_are_recorded_for_a_dynamic
    app = Zui::Application.new do
      state :a, 0
      state :b, 0
      panel :main do
        dynamic(id: :rows) do
          text "a=#{state.a}"
          text "b=#{Fiber.new { state.b }.resume}"
        end
      end
    end
    started(app)

    app.state.b = 3

    texts = app.tree.fetch("main").fetch("children").first.fetch("children").map { |child| child.dig("props", "text") }
    assert_equal ["a=0", "b=3"], texts
  end

  def test_a_scheduler_thread_does_not_contaminate_the_frame_of_another
    store = Zui::StateStore.new(->(*) {})
    store.define(:mine, 0)
    store.define(:theirs, 0)

    _, reads = Zui::StateStore.capture do
      Thread.new { store.theirs }.join
      store.mine
    end

    assert_equal [:mine], reads
  end
end
