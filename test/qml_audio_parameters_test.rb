# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class QmlAudioParametersTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def read(name)
    File.read(File.join(ROOT, name), encoding: "UTF-8")
  end

  def sources(glob)
    Dir[File.join(ROOT, glob)].sort.to_h do |path|
      [path.delete_prefix("#{ROOT}/"), File.read(path, encoding: "UTF-8")]
    end
  end

  # Qt 6 deprecates reading a signal's parameter by its bare name inside a
  # handler and says so on every instantiation ("Parameter "volume" is not
  # declared. Injection of parameters into signal handlers is deprecated"),
  # which is two lines for an AudioOutput and three for an AudioInput. The
  # handlers read the property off the object that owns them instead.
  def test_audio_device_handlers_do_not_rely_on_injected_parameters
    %w[AudioOutput AudioInput MediaPlayer].each do |adapter|
      qml = read("Components/Builtins/#{adapter}.qml")

      refute_match(/\{value:(?:muted|volume|duration)\}|duration:duration/, qml,
                   "#{adapter}.qml reads a signal parameter by its bare name")
    end
  end
end
