# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class QmlFilePickerTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def read(name)
    File.read(File.join(ROOT, name), encoding: "UTF-8")
  end

  def sources(glob)
    Dir[File.join(ROOT, glob)].sort.to_h do |path|
      [path.delete_prefix("#{ROOT}/"), File.read(path, encoding: "UTF-8")]
    end
  end

  # A FileDialog told about an empty path complains that it "cannot set  as a
  # selected file because it doesn't exist", twice per file picker, each time
  # one is created. It has to be told only about a path that exists.
  def test_file_picker_does_not_hand_its_dialog_empty_paths
    qml = read("Components/Builtins/FilePicker.qml")
    dialog = qml[/^  FileDialog \{.*?^  \}/m]

    refute_nil dialog
    refute_match(/^\s*current(?:File|Files|Folder):/, dialog,
                 "FileDialog binds a selection unconditionally; bind it through a Binding with `when`")
    %w[currentFile currentFiles currentFolder].each do |property|
      assert_match(/target: fileDialog\s+property: "#{property}"\s+(?:.*\n){0,12}?\s*when:/, qml,
                   "#{property} is not guarded by a `when` condition")
    end
  end
end
