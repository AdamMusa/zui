# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"
require_relative "../lib/zui"

# Everything the build tooling reads — framework and application source, QML,
# JSON manifests, the output of the tools it shells out to — is UTF-8, whatever
# locale the caller happens to run in. A plain File.read tags those bytes with
# Encoding.default_external instead, which is US-ASCII when LANG is unset, and
# then the first accented character in a comment aborts a scan with "invalid
# byte sequence in US-ASCII". Through Ripper it is worse than an abort: the
# tree shaker reported a file that is perfectly valid as having syntax errors.
#
# With the locale stripped the suite had 152 errors in five test classes. These
# tests fail in the same environment rather than only in a developer's shell.
class SourceEncodingTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  STRIPPED_LOCALE = { "LANG" => nil, "LC_ALL" => nil, "LC_CTYPE" => nil }.freeze

  # /proc/self/status is read by the runtime, not the tooling, is ASCII by
  # definition, and has to keep working on mruby, which has no encoding
  # argument at all.
  LOCALE_DEPENDENT_READS_ALLOWED = {
    "lib/zui/application.rb" => ["/proc/self/status"]
  }.freeze

  def test_no_source_read_in_the_framework_depends_on_the_callers_locale
    sources = Dir[File.join(ROOT, "lib", "**", "*.rb")] +
              Dir[File.join(ROOT, "test", "**", "*.rb")] +
              Dir[File.join(ROOT, "scripts", "**", "*.rb")]
    offenders = sources.sort.flat_map { |path| locale_dependent_reads(path) }

    assert_empty offenders,
                 "these reads are tagged with the caller's locale:\n#{offenders.join("\n")}"
  end

  # A command's output is scanned with regular expressions, so it is handed
  # back as UTF-8 with anything that is not UTF-8 replaced. A linker
  # diagnostic is a tool's chatter, not data worth raising over.
  def test_command_output_is_utf8_whatever_the_tool_emitted
    result = Zui::Command.run(["printf", "caf\xC3\xA9 \xFF done"])

    assert_equal Encoding::UTF_8, result.stdout.encoding
    assert_predicate result.stdout, :valid_encoding?
    assert_includes result.stdout, "café"
  end

  # The behavioural half. LiteSource inlines every framework Ruby source and
  # the application's own, and the tree shaker reads all of that plus every
  # QML file; both have non-ASCII characters in their comments, and both raised
  # here. LiteSource is the one that only reads — the shaker prunes the tree it
  # is pointed at — so it is the one driven directly.
  def test_the_framework_sources_can_be_read_without_a_locale
    script = <<~RUBY
      require "zui"
      abort "locale was not stripped: \#{Encoding.default_external}" if Encoding.default_external == Encoding::UTF_8
      source = Zui::LiteSource.new(project: File.join(#{ROOT.inspect}, "examples", "futuristic_dashboard")).call
      abort "nothing inlined" unless source.include?("class Application")
      puts source.bytesize
    RUBY

    output, error, status = Open3.capture3(
      STRIPPED_LOCALE, RbConfig.ruby, "-I#{File.join(ROOT, 'lib')}", "-e", script
    )

    assert status.success?, error
    assert_operator output.to_i, :>, 10_000
  end

  # Ripper is the worst of the three: handed US-ASCII bytes it does not raise,
  # it returns nil, and the tree shaker turned that into "cannot tree-shake
  # Ruby file with syntax errors" against a file that is perfectly valid.
  def test_ruby_sources_still_parse_without_a_locale
    script = <<~RUBY
      require "ripper"
      abort "locale was not stripped: \#{Encoding.default_external}" if Encoding.default_external == Encoding::UTF_8
      path = File.join(#{ROOT.inspect}, "lib", "zui", "cli.rb")
      abort "Ripper saw a syntax error in \#{path}" unless Ripper.sexp(File.read(path, encoding: "UTF-8"))
      locale_tagged = IO.binread(path).force_encoding(Encoding.default_external)
      abort "the locale default still parses, so this proves nothing" if Ripper.sexp(locale_tagged)
      puts "ok"
    RUBY

    output, error, status = Open3.capture3(
      STRIPPED_LOCALE, RbConfig.ruby, "-e", script
    )

    assert status.success?, error
    assert_equal "ok\n", output
  end

  private

  # A call can be continued over several lines, with `encoding:` on the next
  # one, so the whole call has to be read rather than the line it opens on.
  def locale_dependent_reads(path)
    relative = path.delete_prefix("#{ROOT}/")
    allowed = LOCALE_DEPENDENT_READS_ALLOWED.fetch(relative, [])
    source = File.read(path, encoding: "UTF-8")

    source.enum_for(:scan, /\b(?:File|IO)\.(?:read|readlines|foreach)\(/).filter_map do
      opened = Regexp.last_match.end(0) - 1
      call = source[opened, balanced_length(source, opened)].to_s
      next if call.include?("encoding:")
      next if allowed.any? { |fragment| call.include?(fragment) }

      line = source[0, opened].count("\n") + 1
      "#{relative}:#{line}: #{source.lines[line - 1].strip}"
    end
  end

  def balanced_length(source, opened)
    depth = 0
    source[opened..].each_char.with_index do |character, offset|
      depth += 1 if character == "("
      depth -= 1 if character == ")"
      return offset + 1 if depth.zero?
    end
    source.length - opened
  end
end
