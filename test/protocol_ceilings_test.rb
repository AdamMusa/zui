# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../lib/zui"

# The native client refuses what is past these ceilings and says nothing to
# Ruby, so Ruby has to be the one that refuses first.
class ProtocolCeilingsTest < Minitest::Test
  def normalize(value) = Zui::Value.normalize(value, property: :items)

  def nest(levels, leaf = 1) = levels.times.reduce(leaf) { |inner, _| [inner] }

  def test_a_collection_of_256_items_is_taken_and_257_is_not
    assert_equal 256, normalize(Array.new(256, 1)).length
    error = assert_raises(ArgumentError) { normalize(Array.new(257, 1)) }
    assert_includes error.message, "257 items"
    assert_includes error.message, "items"
  end

  def test_a_hash_of_257_keys_is_not
    assert_equal 256, normalize((1..256).to_h { |index| [index, 1] }).length
    assert_raises(ArgumentError) { normalize((1..257).to_h { |index| [index, 1] }) }
  end

  def test_nesting_stops_at_the_depth_the_client_measures
    # The client allows depth 0 through 8, and a scalar at depth 9 is refused.
    assert_equal nest(8), normalize(nest(8))
    assert_raises(ArgumentError) { normalize(nest(9)) }
  end

  def test_strings_are_limited_to_16384_utf16_code_units
    assert_equal 16_384, normalize("a" * 16_384).length
    assert_raises(ArgumentError) { normalize("a" * 16_385) }
    assert_raises(ArgumentError) { normalize(:a.to_s * 16_385) }
    # Each of these is one character in Ruby and two UTF-16 code units in the
    # client, so 8200 of them are 16400 units.
    assert_raises(ArgumentError) { normalize("\u{1F600}" * 8_200) }
    assert_equal 8_192, normalize("\u{1F600}" * 8_192).length
  end

  def test_a_hash_key_longer_than_128_is_refused
    assert_equal({ "k" * 128 => 1 }, normalize({ "k" * 128 => 1 }))
    assert_raises(ArgumentError) { normalize({ "k" * 129 => 1 }) }
  end

  def test_the_property_is_named_when_a_bound_value_is_too_big
    error = assert_raises(ArgumentError) do
      Zui::Application.new do
        panel :main do
          list = list_view
          bind(list, :items) { Array.new(300) { |index| "row #{index}" } }
        end
      end
    end
    assert_includes error.message, "items"
  end

  def test_a_tree_past_the_live_node_budget_is_built_but_never_sent
    build = lambda do |count|
      Zui::Application.new do
        panel :main do
          column { (count - 2).times { text "x" } }
        end
      end
    end
    output = StringIO.new

    build.call(Zui::MAX_LIVE_NODES).start(output:, error: StringIO.new)
    assert_includes output.string, '"type":"render"'

    output = StringIO.new
    oversized = build.call(Zui::MAX_LIVE_NODES + 1)
    error = assert_raises(Zui::ProtocolError) { oversized.start(output:, error: StringIO.new) }
    assert_includes error.message, "2001 live nodes"
    refute_includes output.string, '"type":"render"'
  end

  def test_a_dynamic_that_grows_past_the_budget_raises_instead_of_sending_a_refused_frame
    app = Zui::Application.new do
      state :rows, 10
      panel :main do
        dynamic(id: :list) { state.rows.times { text "row" } }
      end
    end
    output = StringIO.new
    app.start(output:, error: StringIO.new)
    output.truncate(0)
    output.rewind

    assert_raises(Zui::ProtocolError) { app.state.rows = Zui::MAX_LIVE_NODES }
    refute_includes output.string, "replace_children"
  end
end
