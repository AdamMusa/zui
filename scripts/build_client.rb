#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require_relative "../lib/zui"
require_relative "../lib/zui/client_builder"

output = File.expand_path("../tmp/clients", __dir__)
OptionParser.new do |parser|
  parser.banner = "Usage: build_client.rb [--output DIRECTORY]"
  parser.on("--output DIRECTORY") { |value| output = File.expand_path(value) }
end.parse!

archive = Zui::ClientBuilder.new.build!(output:)
puts archive
