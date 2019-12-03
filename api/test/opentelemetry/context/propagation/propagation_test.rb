# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context::Propagation::Propagation do
  class SimpleInjector
    def initialize(key)
      @key = key
    end

    def inject(context, carrier)
      carrier[@key] = context[@key]
      carrier
    end
  end

  class SimpleExtractor
    def initialize(key)
      @key = key
    end

    def extract(context, carrier)
      context.set_value(@key, carrier[@key])
    end
  end

  let(:propagation) { OpenTelemetry::Context::Propagation::Propagation.new }
  let(:injectors) { %w[k1 k2 k3].map { |k| SimpleInjector.new(k) } }
  let(:extractors) { %w[k1 k2 k3].map { |k| SimpleExtractor.new(k) } }

  after do
    Context.clear
  end

  describe '#inject' do
    it 'returns carrier with empty injectors' do
      Context.with_value('k1', 'v1') do
        Context.with_value('k2', 'v2') do
          Context.with_value('k3', 'v3') do
            carrier_before = {}
            carrier_after = propagation.inject(Context.current, carrier_before)
            _(carrier_before).must_equal(carrier_after)
          end
        end
      end
    end

    it 'injects values from current context into carrier' do
      Context.with_value('k1', 'v1') do
        Context.with_value('k2', 'v2') do
          Context.with_value('k3', 'v3') do
            carrier = propagation.inject(Context.current, {}, injectors)
            _(carrier).must_equal('k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3')
          end
        end
      end
    end
  end

  describe '#extract' do
    it 'returns original context with empty extractors' do
      context_before = Context.current
      carrier = { 'k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3' }
      context_after = propagation.extract(context_before, carrier)
      _(context_before).must_equal(context_after)
    end

    it 'extracts values from carrier into context' do
      carrier = { 'k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3' }
      context = propagation.extract(Context.current, carrier, extractors)
      _(context['k1']).must_equal('v1')
      _(context['k2']).must_equal('v2')
      _(context['k3']).must_equal('v3')
    end
  end
end
