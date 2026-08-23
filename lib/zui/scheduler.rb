# frozen_string_literal: true

module Zui
  class Task
    attr_reader :kind, :interval, :block

    def initialize(kind:, interval:, immediate:, block:)
      @kind = kind
      @interval = interval
      @immediate = immediate
      @block = block
      @mutex = Mutex.new
      @condition = ConditionVariable.new
      @cancelled = false
      @thread = nil
    end

    def start(evaluator, on_error)
      @mutex.synchronize do
        return self if @cancelled || @thread
        if Object.const_defined?(:Thread)
          @thread = Thread.new { run(evaluator, on_error) }
          @thread.name = "zui-#{kind}" if @thread.respond_to?(:name=)
        else
          @thread = :cooperative
          @evaluator = evaluator
          @on_error = on_error
          @next_due = Time.now.to_f + ((kind == :async || @immediate) ? 0 : interval)
        end
      end
      self
    end

    def cancel
      @mutex.synchronize do
        @cancelled = true
        @condition.broadcast
      end
      self
    end

    def join(timeout = nil)
      thread = @mutex.synchronize { @thread }
      thread.join(timeout) if thread && thread != :cooperative
      self
    end

    def tick(now = Time.now.to_f)
      return unless @thread == :cooperative || !Object.const_defined?(:Thread)
      return if cancelled? || now < @next_due
      invoke(@evaluator, @on_error)
      if kind == :every
        @next_due = now + interval
      else
        cancel
      end
    end

    def cancelled?
      @mutex.synchronize { @cancelled }
    end

    private

    def run(evaluator, on_error)
      case kind
      when :async then invoke(evaluator, on_error)
      when :after then invoke(evaluator, on_error) if wait(interval)
      when :every
        invoke(evaluator, on_error) if @immediate && !cancelled?
        while wait(interval)
          invoke(evaluator, on_error)
        end
      end
    end

    def wait(seconds)
      @mutex.synchronize do
        @condition.wait(@mutex, seconds) unless @cancelled
        !@cancelled
      end
    end

    def invoke(evaluator, on_error)
      evaluator.call(block) unless cancelled?
    rescue StandardError => error
      on_error.call(error)
    end
  end

  class Scheduler
    def initialize(evaluator:, on_error:)
      @evaluator = evaluator
      @on_error = on_error
      @tasks = []
      @lock = Mutex.new
      @started = false
    end

    def schedule(kind, interval: 0, immediate: false, &block)
      raise ArgumentError, "task requires a block" unless block
      seconds = Float(interval)
      raise ArgumentError, "task interval must be positive" if kind != :async && !seconds.positive?
      task = Task.new(kind:, interval: seconds, immediate:, block:)
      @lock.synchronize do
        @tasks << task
        task.start(@evaluator, @on_error) if @started
      end
      task
    end

    def start
      @lock.synchronize do
        @started = true
        @tasks.each { |task| task.start(@evaluator, @on_error) }
      end
      self
    end

    def stop
      tasks = @lock.synchronize do
        @started = false
        @tasks.dup
      end
      tasks.each(&:cancel)
      tasks.each { |task| task.join(1) }
      self
    end

    def tick(now = Time.now.to_f)
      tasks = @lock.synchronize { @tasks.dup }
      tasks.each { |task| task.tick(now) }
      self
    end
  end
end
