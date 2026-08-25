# frozen_string_literal: true

unless Object.const_defined?(:Mutex)
  class Mutex
    def synchronize
      yield
    end
  end
end

unless Object.const_defined?(:ConditionVariable)
  class ConditionVariable
    def wait(_mutex, _seconds = nil)
      self
    end

    def broadcast
      self
    end
  end
end
