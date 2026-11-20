# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class StateStoreReentrancyTest < Minitest::Test
  def setup
    @reports = []
    @store = Zui::StateStore.new(->(changes) { @reports << changes.map(&:first) })
    @store.define(:a, 1)
    @store.define(:b, 10)
  end

  def test_an_update_block_may_read_other_state
    assert_equal 11, @store.update(:a) { |a| a + @store.b }
    assert_equal 11, @store.a
    assert_equal [%i[a]], @reports
  end

  def test_an_update_block_may_read_its_own_key_through_the_store
    assert_equal 2, @store.update(:a) { |a| a + @store.a }
  end

  def test_a_block_that_raises_releases_the_lock
    assert_raises(RuntimeError) { @store.update(:a) { raise "boom" } }

    assert_equal 5, @store.update(:a) { 5 }
  end

  def test_updates_stay_atomic_across_threads_while_reading_other_state
    threads = 8.times.map { Thread.new { 200.times { @store.update(:a) { |a| a + @store.b - 9 } } } }
    threads.each(&:join)

    assert_equal 1 + 8 * 200, @store.a
  end
end
