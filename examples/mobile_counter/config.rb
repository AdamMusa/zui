# frozen_string_literal: true

Zui::Dist.configure do
  name "Zui Mobile Counter"
  identifier "dev.zui.mobile-counter"
  version "0.1.0"
  publisher "Zui Project"
  description "A touch-first Zui counter for mobile platforms."
  license "MIT"
  homepage "https://github.com/AdamMusa/zui"

  icon linux: "assets/ruby.png",
       macos: "assets/ruby.icns",
       windows: "assets/ruby.ico",
       android: "assets/ruby.png",
       ios: "assets/ruby.png"

  categories "Utility", "Development"
end
