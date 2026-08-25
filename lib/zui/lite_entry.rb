# frozen_string_literal: true

module Zui
  def self.app(&definition)
    Application.new(&definition).run
  end

  class << self
    alias application app
  end
end
