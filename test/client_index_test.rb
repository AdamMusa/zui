# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../lib/zui"
require_relative "support/client_model"

# Drives an Application and replays everything it emitted into ClientModel.
class ClientIndexTest < Minitest::Test
  def connect(app)
    @output = StringIO.new
    app.start(output: @output, error: StringIO.new)
    @client = ClientModel.new
    @read = 0
    sync
  end

  def sync
    lines = @output.string.lines
    @client.feed(lines[@read..].join)
    @read = lines.length
  end

  def assert_client_matches(app)
    sync
    assert_empty @client.refusals, "the client refused part of the stream"
    assert_equal app.tree, @client.tree
  end

  def test_an_inner_dynamic_that_is_replaced_by_the_one_around_it_queues_no_stale_patch
    app = Zui::Application.new do
      state :show, true
      state :v, 0
      state :other, 0
      panel :main do
        other = text "", id: :other_text
        bind(other, :text) { "other=#{state.other}" }
        dynamic(id: :outer) do
          if state.show
            dynamic(id: :inner) { text "v=#{state.v}" }
          else
            text "hidden #{state.v}"
          end
        end
      end
    end
    connect(app)

    app.state.transaction do
      app.state.show = false
      app.state.v = 5
      app.state.other = 9
    end

    assert_client_matches(app)
  end

  def test_the_same_in_the_other_direction
    app = Zui::Application.new do
      state :show, false
      state :v, 0
      state :other, 0
      panel :main do
        other = text "", id: :other_text
        bind(other, :text) { "other=#{state.other}" }
        dynamic(id: :outer) do
          if state.show
            dynamic(id: :inner) { text "v=#{state.v}" }
          else
            text "hidden #{state.v}"
          end
        end
      end
    end
    connect(app)

    app.state.transaction do
      app.state.show = true
      app.state.v = 5
      app.state.other = 9
    end
    assert_client_matches(app)

    app.state.transaction do
      app.state.show = false
      app.state.v = 6
      app.state.other = 10
    end
    assert_client_matches(app)
  end

  def test_three_levels_of_dynamic_all_changing_at_once
    app = Zui::Application.new do
      state :a, 0
      state :b, 0
      state :c, 0
      state :other, 0
      panel :main do
        other = text "", id: :other_text
        bind(other, :text) { "other=#{state.other}" }
        dynamic(id: :l1) do
          if state.a.even?
            dynamic(id: :l2) do
              if state.b.even?
                dynamic(id: :l3) { text "c=#{state.c}" }
              else
                text "b odd"
              end
            end
          else
            text "a odd"
          end
        end
      end
    end
    connect(app)

    10.times do |step|
      app.state.transaction do
        app.state.a = step
        app.state.b = step / 2
        app.state.c = step
        app.state.other = step
      end
      assert_client_matches(app)
    end
  end
end
