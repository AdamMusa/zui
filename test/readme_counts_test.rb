# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class ReadmeCountsTest < Minitest::Test
  # The README states the size of the component registry in several places. Every one of them has
  # to come from `Zui::COMPONENTS`, so a landed component cannot leave the documentation behind.
  def test_every_component_count_in_the_readme_matches_the_registry
    stale = Zui::ReadmeCounts.stale

    assert_empty stale,
                 "README.md line(s) #{stale.keys.join(', ')} document " \
                 "#{stale.values.flatten.uniq.join(', ')} components instead of " \
                 "#{Zui::ReadmeCounts.expected}; run `rake readme:counts`"
  end

  def test_the_readme_states_the_count_in_every_place_it_used_to
    documented = Zui::ReadmeCounts.documented

    assert_equal 5, documented.size
    assert_equal 6, documented.values.flatten.size
    assert_equal [Zui::COMPONENTS.size], documented.values.flatten.uniq
  end

  def test_rewriting_the_counts_is_idempotent
    assert_equal Zui::ReadmeCounts.read, Zui::ReadmeCounts.rewrite
  end

  # The catalog table breaks the registry down by category. The numbers come from the coverage
  # checklist, so the table and the checklist cannot disagree and the table has to add up.
  def test_the_category_table_matches_the_coverage_checklist
    documented = Zui::ReadmeCounts.documented_categories

    assert_equal Zui::ReadmeCounts.category_counts, documented
    assert_equal Zui::COMPONENTS.size, documented.values.sum
  end

  def test_the_coverage_checklist_documents_every_registered_component_exactly_once
    listed = Zui::ReadmeCounts.coverage_sections.values.flatten
    registered = Zui::COMPONENTS.keys.map(&:to_s)

    assert_empty registered - listed, "missing from docs/component-coverage.md"
    assert_empty listed - registered, "documented in docs/component-coverage.md but not registered"
    assert_equal listed.size, listed.uniq.size
  end

  def test_the_architecture_diagram_keeps_its_width_when_the_count_changes
    line = "│ catalog · 41-component QML catalog   │\n"
    padded = Zui::ReadmeCounts.send(:rewrite_line, line)

    assert_includes padded, "#{Zui::COMPONENTS.size}-component QML catalog"
    assert_equal line.chomp.length, padded.chomp.length
    assert_equal line.chomp.length, Zui::ReadmeCounts.send(:rewrite_line, padded).chomp.length
  end
end
