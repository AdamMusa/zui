# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class StateStoreTransactionTest < Minitest::Test
  def setup
    @reports = []
    @store = Zui::StateStore.new(->(changes) { @reports << changes.map(&:first) })
    @store.define(:first, 0)
    @store.define(:second, 0)
  end

  def test_a_transaction_reports_its_writes_once
    @store.transaction do
      @store.first = 1
      @store.second = 1
    end

    assert_equal [%i[first second]], @reports
  end

  def test_nested_transactions_report_once_at_the_outermost_close
    @store.transaction do
      @store.first = 1
      @store.transaction { @store.second = 1 }
      assert_empty @reports
    end

    assert_equal [%i[first second]], @reports
  end

  def test_a_transaction_called_without_a_block_does_not_break_the_next_one
    assert_raises(ArgumentError) { @store.transaction }

    @store.transaction do
      @store.first = 1
      @store.second = 1
    end

    assert_equal [%i[first second]], @reports
  end

  def test_a_transaction_that_raises_still_reports_what_it_wrote_and_closes
    assert_raises(RuntimeError) do
      @store.transaction do
        @store.first = 1
        raise "boom"
      end
    end
    assert_equal [%i[first]], @reports

    @store.transaction do
      @store.first = 2
      @store.second = 2
    end
    assert_equal [%i[first], %i[first second]], @reports
  end
end
