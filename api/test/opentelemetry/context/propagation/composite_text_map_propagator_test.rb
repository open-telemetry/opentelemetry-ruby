# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context::Propagation::CompositeTextMapPropagator do
  Context = OpenTelemetry::Context

  class TestInjector
    def initialize(key)
      @key = key
    end

    def inject(carrier, context:, setter: nil)
      if setter
        setter.set(carrier, @key, context[@key])
      else
        carrier[@key] = context[@key]
      end
      carrier
    end

    def fields
      [@key]
    end
  end

  class TestExtractor
    def initialize(key)
      @key = key
    end

    def extract(carrier, context:, getter: nil)
      value = getter ? getter.get(carrier, @key) : carrier[@key]
      context.set_value(@key, value)
    end
  end

  class BuggyInjector
    def inject(carrier, context:, setter: nil)
      raise 'oops'
    end
  end

  class BuggyExtractor
    def extract(carrier, context:, getter: nil)
      raise 'oops'
    end
  end

  let(:propagator) do
    OpenTelemetry::Context::Propagation::CompositeTextMapPropagator.compose(injectors: injectors, extractors: extractors)
  end

  after do
    Context.clear
  end

  describe 'with working injectors / extractors' do
    let(:injectors) { %w[k1 k2 k3].map { |k| TestInjector.new(k) } }
    let(:extractors) { %w[k1 k2 k3].map { |k| TestExtractor.new(k) } }

    describe '#inject' do
      it 'injects values from current context into carrier' do
        Context.with_values('k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3') do
          carrier = {}
          propagator.inject(carrier)
          _(carrier).must_equal('k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3')
        end
      end

      it 'accepts explicit context' do
        Context.with_values('k1' => 'v1', 'k2' => 'v2') do
          ctx = Context.current.set_value('k3', 'v3') do
            carrier = {}
            propagator.inject(carrier, context: ctx)
            _(carrier).must_equal('k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3')
          end
        end
      end

      it 'executes setter' do
        Context.with_values('k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3') do
          setter = Class.new do
            def set(carrier, key, value)
              carrier[key.upcase] = value.upcase
            end
          end.new
          result = {}
          propagator.inject(result, setter: setter)
          _(result).must_equal('K1' => 'V1', 'K2' => 'V2', 'K3' => 'V3')
        end
      end
    end

    describe '#extract' do
      it 'extracts values from carrier into context' do
        carrier = { 'k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3' }
        context = propagator.extract(carrier)
        _(context['k1']).must_equal('v1')
        _(context['k2']).must_equal('v2')
        _(context['k3']).must_equal('v3')
      end

      it 'accepts explicit context' do
        ctx = Context.empty.set_value('k0', 'v0')
        carrier = { 'k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3' }
        context = propagator.extract(carrier, context: ctx)
        _(context['k0']).must_equal('v0')
        _(context['k1']).must_equal('v1')
        _(context['k2']).must_equal('v2')
        _(context['k3']).must_equal('v3')
      end

      it 'executes getter' do
        carrier = { 'k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3' }
        getter = Class.new do
          def get(carrier, key)
            carrier[key]&.upcase
          end
        end.new
        context = propagator.extract(carrier, getter: getter)
        _(context['k1']).must_equal('V1')
        _(context['k2']).must_equal('V2')
        _(context['k3']).must_equal('V3')
      end
    end

    describe '#fields' do
      it 'returns all fields from injectors' do
        _(propagator.fields).must_equal(%w[k1 k2 k3])
      end
    end
  end

  describe 'with buggy injectors / extractors' do
    let(:injectors) do
      %w[k1 k2 k3].map do |k|
        k == 'k2' ? BuggyInjector.new : TestInjector.new(k)
      end
    end
    let(:extractors) do
      %w[k1 k2 k3].map do |k|
        k == 'k2' ? BuggyExtractor.new : TestExtractor.new(k)
      end
    end

    describe '#inject' do
      it 'injects values from working injectors' do
        Context.with_values('k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3') do
          carrier = {}
          propagator.inject(carrier)
          _(carrier).must_equal('k1' => 'v1', 'k3' => 'v3')
        end
      end
    end

    describe '#extract' do
      it 'extracts values from working extractors' do
        carrier = { 'k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3' }
        context = propagator.extract(carrier)
        _(context['k1']).must_equal('v1')
        _(context['k2']).must_be_nil
        _(context['k3']).must_equal('v3')
      end
    end
  end
end
