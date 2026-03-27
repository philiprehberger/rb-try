# frozen_string_literal: true

require 'timeout'
require_relative 'try/version'

module Philiprehberger
  module Try
    def self.call(timeout: nil, &block)
      value = if timeout
                Timeout.timeout(timeout, &block)
              else
                yield
              end
      Success.new(value)
    rescue StandardError => e
      Failure.new(e)
    end

    class Success
      attr_reader :value

      def initialize(value)
        @value = value
        freeze
      end

      def value!
        @value
      end

      def success?
        true
      end

      def failure?
        false
      end

      def or_else(_default)
        self
      end

      def or_try
        self
      end

      def on(_exception_class)
        self
      end

      def on_error
        self
      end

      def map
        Try.call { yield @value }
      end
    end

    class Failure
      attr_reader :error

      def initialize(error)
        @error = error
        freeze
      end

      def value
        nil
      end

      def value!
        raise @error
      end

      def success?
        false
      end

      def failure?
        true
      end

      def or_else(default)
        Success.new(default)
      end

      def or_try(&)
        Try.call(&)
      end

      def on(exception_class, &block)
        return Try.call { block.call(@error) } if @error.is_a?(exception_class)

        self
      end

      def on_error
        yield @error
        self
      end

      def map
        self
      end
    end
  end
end
