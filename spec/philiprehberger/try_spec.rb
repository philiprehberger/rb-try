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
      result = described_class.call { raise RuntimeError, 'nope' }
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
end
