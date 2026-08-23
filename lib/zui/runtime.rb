# frozen_string_literal: true

require "fileutils"

module Zui
  module Runtime
    module_function

    QML_FILES = %w[Desktop.qml Service.qml ControlNode.qml].freeze
    QML_DIRECTORIES = %w[Components Controls Theme].freeze

    def install_qml(destination, framework_root: FRAMEWORK_ROOT)
      FileUtils.mkdir_p(destination)
      QML_FILES.each do |name|
        FileUtils.cp(File.join(framework_root, name), File.join(destination, name))
      end
      QML_DIRECTORIES.each do |name|
        FileUtils.cp_r(File.join(framework_root, name), File.join(destination, name))
      end
      destination
    end
  end
end
