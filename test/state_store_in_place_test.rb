# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../lib/zui"

# A mutable value changed in place comes back as the object already stored.
class StateStoreInPlaceTest < Minitest::Test
  def setup
    @reports = []
    @store = Zui::StateStore.new(->(changes) { @reports << changes.map(&:first) })
    @store.define(:items, ["a"])
    @store.define(:name, +"x")
    @store.define(:frozen_items, ["a"].freeze)
    @store.define(:count, 1)
  end

  def test_update_that_mutates_in_place_is_reported
    @store.update(:items) { |items| items << "b" }

    assert_equal [%i[items]], @reports
  end

  def test_reassigning_a_mutated_object_is_reported
    @store.items << "b"
    @store.items = @store.items

    assert_equal [%i[items]], @reports
  end

  def test_a_string_appended_to_in_place_is_reported
    @store.update(:name) { |name| name << "y" }

    assert_equal [%i[name]], @reports
  end

  def test_an_equal_but_distinct_value_and_immutables_are_still_not_changes
    @store.items = ["a"]
    @store.frozen_items = @store.frozen_items
    @store.count = 1
    @store.update(:count) { |count| count }

    assert_empty @reports
  end

  def test_a_bound_reader_sees_an_in_place_update_and_sends_one_patch
    app = Zui::Application.new do
      state :items, ["a"]
      panel :main do
        label = text "", id: :summary
        bind(label, :text) { "items=#{state.items.join(',')}" }
        dynamic(id: :rows) { state.items.each { |item| text item } }
      end
    end
    output = StringIO.new
    app.start(output:, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.state.update(:items) { |items| items << "b" }

    patches = output.string.lines.map { |line| JSON.parse(line) }.select { |message| message["type"] == "patch" }
    assert_equal %w[replace_children set], patches.map { |patch| patch["op"] }
    assert_equal "items=a,b", app.tree.fetch("main").fetch("children").first.dig("props", "text")

    output.truncate(0)
    output.rewind
    app.state.update(:items) { |items| items }
    refute_includes output.string, '"patch"', "a reader that finds nothing new sends nothing"
  end
end
