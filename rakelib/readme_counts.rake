# frozen_string_literal: true

namespace :readme do
  desc "Rewrite the component counts in README.md from the component registry"
  task :counts do
    $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
    require "zui"

    if Zui::ReadmeCounts.write!
      puts "README.md now documents #{Zui::ReadmeCounts.expected} components"
    else
      puts "README.md already documents #{Zui::ReadmeCounts.expected} components"
    end
  end
end
