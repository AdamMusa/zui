#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require_relative "../lib/zui"
require_relative "../lib/zui/client_packager"

options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: package_client.rb --source DIRECTORY --output DIRECTORY --executable PATH [--qt-version VERSION]"
  parser.on("--source DIRECTORY") { |value| options[:source] = value }
  parser.on("--output DIRECTORY") { |value| options[:output] = value }
  parser.on("--executable PATH") { |value| options[:executable] = value }
  parser.on("--qt-version VERSION") { |value| options[:qt_version] = value }
end.parse!

%i[source output executable].each do |name|
  abort "package_client.rb: --#{name.to_s.tr('_', '-')} is required" unless options[name]
end

archive = Zui::ClientPackager.new.package(**options)
puts archive
