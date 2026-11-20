# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../lib/zui"
require_relative "support/client_model"

# Builds random interfaces out of nested `dynamic`s, bindings and plain
# nodes, drives random writes and transactions through them, and replays what
# the application emitted into ClientModel after every step. Whatever the
# shape, the client's index must end each step equal to the application's tree
# and must never have refused anything.
class RandomStreamTest < Minitest::Test
  KEYS = %i[k0 k1 k2 k3].freeze

  # A recipe is plain data so a failing seed can be printed and replayed.
  def recipe(rng, depth)
    Array.new(1 + rng.rand(3)) { entry(rng, depth) }
  end

  def entry(rng, depth)
    roll = rng.rand(10)
    if depth < 3 && roll < 4
      { kind: :dynamic, key: KEYS.sample(random: rng), modulo: 2 + rng.rand(2), explicit: rng.rand(3).zero?,
        branches: Array.new(2) { recipe(rng, depth + 1) } }
    elsif roll < 7
      { kind: :bound, key: KEYS.sample(random: rng), extra: KEYS.sample(random: rng) }
    elsif roll < 9
      { kind: :static, key: KEYS.sample(random: rng) }
    else
      { kind: :column, children: recipe(rng, depth + 1) }
    end
  end

  def render(builder, entries, path)
    me = self
    entries.each_with_index do |entry, index|
      here = "#{path}#{index}"
      case entry[:kind]
      when :dynamic
        options = entry[:explicit] ? { id: "dyn#{here}" } : {}
        builder.dynamic(**options) do
          branch = state.public_send(entry[:key]) % entry[:modulo]
          me.render(self, entry[:branches][branch % entry[:branches].length], "#{here}.#{branch}.")
        end
      when :bound
        node = builder.text("", id: "b#{here}")
        builder.bind(node, :text) { "#{state.public_send(entry[:key])}/#{state.public_send(entry[:extra]) % 2}" }
      when :static
        builder.text "static #{builder.state.public_send(entry[:key])}"
      when :column
        builder.column { me.render(self, entry[:children], "#{here}.") }
      end
    end
  end

  def build(entries)
    test = self
    Zui::Application.new do
      KEYS.each { |key| state key, 0 }
      panel :main do
        test.render(self, entries, "r")
      end
    end
  end

  def drive(seed)
    rng = Random.new(seed)
    entries = recipe(rng, 0)
    app = build(entries)
    output = StringIO.new
    app.start(output:, error: StringIO.new)
    client = ClientModel.new
    read = 0
    sync = lambda do
      lines = output.string.lines
      client.feed(lines[read..].join)
      read = lines.length
    end
    sync.call
    30.times do |step|
      writes = Array.new(1 + rng.rand(3)) { [KEYS.sample(random: rng), rng.rand(6)] }
      step_start = read
      grouped = rng.rand(2).zero?
      if grouped
        app.state.transaction { writes.each { |key, value| app.state.public_send(:"#{key}=", value) } }
      else
        writes.each { |key, value| app.state.public_send(:"#{key}=", value) }
      end
      sync.call
      emitted = output.string.lines[step_start..].map { |line| line[0, 400] }.join
      context = "seed #{seed}, step #{step}, #{grouped ? 'transaction' : 'separate writes'} #{writes.inspect}\n#{emitted}"
      assert_empty client.refusals, "client refused part of the stream (#{context})"
      assert_equal app.tree, client.tree, "client diverged from the application (#{context})"
    end
  end

  def test_random_interfaces_stay_in_step_with_the_client
    (1..Integer(ENV.fetch("ZUI_FUZZ_SEEDS", 100))).each { |seed| drive(seed) }
  end
end
