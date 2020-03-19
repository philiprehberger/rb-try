# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Try do
  it 'has a version number' do
    expect(Philiprehberger::Try::VERSION).not_to be_nil
  end

  describe '.call' do
    context 'when the block succeeds' do
      subject(:result) { described_class.call { 42 } }

      it 'returns a Success' do
        expect(result).to be_a(described_class::Success)
      end

      it 'wraps the value' do
        expect(result.value).to eq(42)
      end

      it 'returns value with value!' do
        expect(result.value!).to eq(42)
      end

      it 'is success?' do
        expect(result.success?).to be true
      end

      it 'is not failure?' do
        expect(result.failure?).to be false
      end
    end

    context 'when the block raises' do
      subject(:result) { described_class.call { raise StandardError, 'boom' } }

      it 'returns a Failure' do
        expect(result).to be_a(described_class::Failure)
      end

      it 'returns nil for value' do
        expect(result.value).to be_nil
      end

      it 'raises with value!' do
        expect { result.value! }.to raise_error(StandardError, 'boom')
      end

      it 'is not success?' do
        expect(result.success?).to be false
      end

      it 'is failure?' do
        expect(result.failure?).to be true
      end

      it 'returns the exception via error' do
        expect(result.error).to be_a(StandardError)
        expect(result.error.message).to eq('boom')
      end
    end
  end

  describe '#or_else' do
    it 'ignores default on Success' do
      result = described_class.call { 42 }.or_else(0)
      expect(result.value).to eq(42)
    end

    it 'returns default wrapped in Success on Failure' do
      result = described_class.call { raise StandardError }.or_else(0)
      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq(0)
    end
  end

  describe '#or_try' do
    it 'ignores block on Success' do
      result = described_class.call { 42 }.or_try { 99 }
      expect(result.value).to eq(42)
    end

    it 'tries block on Failure' do
      result = described_class.call { raise StandardError }.or_try { 99 }
      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq(99)
    end

    it 'chains multiple or_try calls' do
      result = described_class
               .call { raise StandardError, 'first' }
               .or_try { raise StandardError, 'second' }
               .or_try { 'third' }

      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq('third')
    end
  end

  describe '#on' do
    it 'matches a specific exception class' do
      result = described_class.call { raise ArgumentError, 'bad arg' }
                              .on(ArgumentError) { |e| "recovered from #{e.message}" }

      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq('recovered from bad arg')
    end

    it 'ignores non-matching exception class' do
      result = described_class.call { raise 'nope' }
                              .on(ArgumentError) { |_e| 'recovered' }

      expect(result).to be_a(described_class::Failure)
      expect(result.error).to be_a(RuntimeError)
    end

    it 'returns self on Success' do
      result = described_class.call { 42 }.on(StandardError) { |_e| 'recovered' }
      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq(42)
    end
  end

  describe '#on_error' do
    it 'calls block with error for side effects' do
      captured = nil
      result = described_class.call { raise StandardError, 'oops' }
                              .on_error { |e| captured = e.message }

      expect(captured).to eq('oops')
      expect(result).to be_a(described_class::Failure)
    end

    it 'returns self on Success' do
      called = false
      result = described_class.call { 42 }.on_error { |_e| called = true }

      expect(called).to be false
      expect(result.value).to eq(42)
    end
  end

  describe '#map' do
    it 'transforms success value' do
      result = described_class.call { 10 }.map { |v| v * 2 }
      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq(20)
    end

    it 'propagates failure' do
      result = described_class.call { raise StandardError, 'fail' }.map { |v| v * 2 }
      expect(result).to be_a(described_class::Failure)
      expect(result.error.message).to eq('fail')
    end

    it 'wraps map errors in Failure' do
      result = described_class.call { 10 }.map { |_v| raise StandardError, 'map error' }
      expect(result).to be_a(described_class::Failure)
      expect(result.error.message).to eq('map error')
    end
  end

  describe 'timeout' do
    it 'succeeds within time limit' do
      result = described_class.call(timeout: 1) { 'fast' }
      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq('fast')
    end

    it 'fails when block exceeds timeout' do
      result = described_class.call(timeout: 0.1) { sleep 1 }
      expect(result).to be_a(described_class::Failure)
      expect(result.error).to be_a(Timeout::Error)
    end
  end

  describe 'nested or_try chains (3+ deep)' do
    it 'falls through multiple failures to final success' do
      result = described_class
               .call { raise StandardError, 'first' }
               .or_try { raise StandardError, 'second' }
               .or_try do
        raise StandardError,
              'third'
      end
               .or_try { 'fourth' }

      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq('fourth')
    end

    it 'stops at first success in chain' do
      result = described_class
               .call { raise StandardError }
               .or_try { 'recovered' }
               .or_try { 'never reached' }

      expect(result.value).to eq('recovered')
    end

    it 'returns Failure when all or_try blocks fail' do
      result = described_class
               .call { raise StandardError, 'a' }
               .or_try { raise StandardError, 'b' }
               .or_try do
        raise StandardError,
              'c'
      end

      expect(result).to be_a(described_class::Failure)
      expect(result.error.message).to eq('c')
    end
  end

  describe '#on_error side effect without changing result' do
    it 'returns Failure unchanged after side effect' do
      log = []
      result = described_class.call { raise StandardError, 'err' }
                              .on_error { |e| log << e.message }

      expect(result).to be_a(described_class::Failure)
      expect(log).to eq(['err'])
    end

    it 'can chain on_error with or_else' do
      log = []
      result = described_class.call { raise StandardError, 'err' }
                              .on_error { |e| log << e.message }
                              .or_else('default')

      expect(result.value).to eq('default')
      expect(log).to eq(['err'])
    end
  end

  describe '#value! on success returns value' do
    it 'returns the wrapped value directly' do
      result = described_class.call { 'hello' }
      expect(result.value!).to eq('hello')
    end

    it 'returns nil value correctly' do
      result = described_class.call { nil }
      expect(result.value!).to be_nil
    end
  end

  describe '#map on success and failure' do
    it 'chains multiple maps on success' do
      result = described_class.call { 2 }
                              .map { |v| v * 3 }
                              .map { |v| v + 1 }

      expect(result.value).to eq(7)
    end

    it 'skips map on failure and preserves original error' do
      result = described_class.call { raise ArgumentError, 'bad' }
                              .map { |v| v * 2 }
                              .map { |v| v + 1 }

      expect(result).to be_a(described_class::Failure)
      expect(result.error.message).to eq('bad')
    end
  end

  describe '#on with specific exception not matching' do
    it 'does not recover when exception class does not match' do
      result = described_class.call { raise 'rt' }
                              .on(ArgumentError) { |_e| 'recovered' }

      expect(result).to be_a(described_class::Failure)
      expect(result.error).to be_a(RuntimeError)
    end

    it 'recovers when exception class matches exactly' do
      result = described_class.call { raise ArgumentError, 'arg' }
                              .on(ArgumentError) { |e| "fixed: #{e.message}" }

      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq('fixed: arg')
    end

    it 'matches subclass exceptions' do
      result = described_class.call { raise ArgumentError, 'sub' }
                              .on(StandardError) { |_e| 'caught' }

      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq('caught')
    end
  end

  describe 'chaining multiple .on handlers' do
    it 'applies the first matching handler' do
      result = described_class.call { raise ArgumentError, 'arg' }
                              .on(ArgumentError) { |_e| 'arg handler' }
                              .on(RuntimeError) { |_e| 'rt handler' }

      expect(result).to be_a(described_class::Success)
      expect(result.value).to eq('arg handler')
    end

    it 'skips .on on success from prior handler' do
      result = described_class.call { raise ArgumentError }
                              .on(ArgumentError) { 'fixed' }
                              .on(StandardError) { 'should not run' }

      expect(result.value).to eq('fixed')
    end
  end

  describe 'Success is frozen' do
    it 'freezes the Success result' do
      result = described_class.call { 'data' }
      expect(result).to be_frozen
    end
  end

  describe 'Failure is frozen' do
    it 'freezes the Failure result' do
      result = described_class.call { raise StandardError }
      expect(result).to be_frozen
    end
  end
end
