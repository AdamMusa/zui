# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class QmlHandwritingInputTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def read(name)
    File.read(File.join(ROOT, name), encoding: "UTF-8")
  end

  def sources(glob)
    Dir[File.join(ROOT, glob)].sort.to_h do |path|
      [path.delete_prefix("#{ROOT}/"), File.read(path, encoding: "UTF-8")]
    end
  end

  # HandwritingInputPanel dereferences `inputPanel` while it is being created,
  # so built without one (the showcase declares it that way: "declare cleanly
  # and stay inert") Qt's own QML threw seven "Cannot read property ... of null"
  # errors on every build. The panel is only created once its input panel exists.
  def test_handwriting_input_creates_its_panel_only_once_it_has_an_input_panel
    qml = read("Components/Builtins/HandwritingInput.qml")

    assert_match(/^Item \{/, qml, "the adapter's root must not be the panel itself")
    assert_match(/Loader \{.*?active: root\.panelTarget !== null.*?sourceComponent: HandwritingInputPanel \{/m, qml)
  end
end
