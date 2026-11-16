# frozen_string_literal: true

module Zui
  # Keeps the component counts written in README.md derived from the component registry.
  #
  # The README states the number of built-in components in several places: the shields badge, the
  # feature table, the catalog section, the architecture diagram and the documentation link table.
  # Every one of them is a copy of `Zui::COMPONENTS.size`, so each is matched by a pattern here.
  # `rake readme:counts` rewrites them and `test/readme_counts_test.rb` fails when they drift.
  module ReadmeCounts
    README_PATH = File.expand_path("../../README.md", __dir__)
    COVERAGE_PATH = File.expand_path("../../docs/component-coverage.md", __dir__)
    # Each pattern wraps the count in its only capture group.
    PATTERNS = [
      /alt="(\d+) components"/,
      /components-(\d+)-/,
      %r{<strong>(\d+) named components</strong>},
      /registers \*\*(\d+) built-in components\*\*/,
      /(\d+)-component QML catalog/,
      /examples for all (\d+) components/
    ].freeze
    # Lines of the architecture diagram have a fixed width, so a changed digit count has to be
    # absorbed by the padding in front of the closing box character.
    BOX_LINE = /\A│.*│\s*\z/
    # `| Category | Count | Representative components |` in the component catalog table. The
    # per-category numbers come from the checklist sections of docs/component-coverage.md, which
    # the suite keeps in step with the registry.
    CATEGORY_ROW = /\A\| (?<category>[^|]*[^| ]) +\| +(?<count>\d+) \|/

    class << self
      def expected = COMPONENTS.size

      def read = File.read(README_PATH, encoding: "UTF-8")

      # The component names listed per section of the coverage checklist.
      def coverage_sections
        section = nil
        File.read(COVERAGE_PATH, encoding: "UTF-8").each_line.each_with_object({}) do |line, sections|
          if (heading = line[/\A## (.+)$/, 1])
            section = heading
          elsif (name = line[/\A- \[[x ]\] (\S+)/, 1])
            (sections[section] ||= []) << name
          end
        end
      end

      def category_counts
        coverage_sections.transform_values(&:size)
      end

      # Every category count the README states, as { category => count }.
      def documented_categories(text = read)
        text.each_line.filter_map do |line|
          match = line.match(CATEGORY_ROW)
          [match[:category], Integer(match[:count], 10)] if match
        end.to_h
      end

      # Every count the README states, as { line number => count }.
      def documented(text = read)
        text.each_line.with_index(1).each_with_object({}) do |(line, number), counts|
          PATTERNS.each do |pattern|
            line.scan(pattern) { |(count)| (counts[number] ||= []) << Integer(count, 10) }
          end
        end
      end

      def stale(text = read)
        documented(text).reject { |_number, counts| counts.all?(expected) }
      end

      def rewrite(text = read)
        text.each_line.map { |line| rewrite_line(line) }.join
      end

      def write!
        updated = rewrite
        return false if updated == read

        File.write(README_PATH, updated)
        true
      end

      private

      def rewrite_line(line)
        updated = PATTERNS.reduce(line) do |current, pattern|
          current.gsub(pattern) { |match| match.sub(/\d+/, expected.to_s) }
        end
        updated = rewrite_category(updated)
        return updated if updated == line || !line.match?(BOX_LINE)

        pad(updated, line.chomp.length)
      end

      def rewrite_category(line)
        match = line.match(CATEGORY_ROW)
        count = match && category_counts[match[:category]]
        return line unless count

        line.sub(CATEGORY_ROW) { |row| row.sub(/\d+/, count.to_s) }
      end

      def pad(line, width)
        difference = width - line.chomp.length
        return line if difference.zero?

        body = line.chomp
        if difference.positive?
          body.sub(/(\s*)(│)\z/) { "#{::Regexp.last_match(1)}#{' ' * difference}│" }
        else
          body.sub(/\s{#{-difference}}(\s*│)\z/, '\1')
        end + "\n"
      end
    end
  end
end
