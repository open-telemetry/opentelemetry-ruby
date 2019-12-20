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

  describe '.http_injectors' do
    it 'is settable' do
      _(propagation.http_injectors).must_equal([])
      propagation.http_injectors = injectors
      _(propagation.http_injectors).must_equal(injectors)
    end
  end

  describe '.http_extractors' do
    it 'is settable' do
      _(propagation.http_extractors).must_equal([])
      propagation.http_extractors = extractors
      _(propagation.http_extractors).must_equal(extractors)
    end
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

    it 'uses global injectors' do
      propagation.http_injectors = injectors
      Context.with_value('k1', 'v1') do
        Context.with_value('k2', 'v2') do
          Context.with_value('k3', 'v3') do
            carrier = propagation.inject(Context.current, {})
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

    it 'uses global extractors' do
      propagation.http_extractors = extractors
      carrier = { 'k1' => 'v1', 'k2' => 'v2', 'k3' => 'v3' }
      context = propagation.extract(Context.current, carrier)
      _(context['k1']).must_equal('v1')
      _(context['k2']).must_equal('v2')
      _(context['k3']).must_equal('v3')
    end
  end

  describe '#http_trace_context_extractor, #rack_http_trace_context_extractor' do
    it 'returns an instance of HttpTraceContextExtractor' do
      %i[http_trace_context_extractor rack_http_trace_context_extractor].each do |extractor_method|
        extractor = propagation.send(extractor_method)
        _(extractor).must_be_instance_of(
          Trace::Propagation::HttpTraceContextExtractor
        )
      end
    end
  end

  describe '#http_trace_context_injector, #rack_http_trace_context_injector' do
    it 'returns an instance of HttpTraceContextInjector' do
      %i[http_trace_context_injector rack_http_trace_context_injector].each do |injector_method|
        injector = propagation.send(injector_method)
        _(injector).must_be_instance_of(
          Trace::Propagation::HttpTraceContextInjector
        )
      end
    end
  end

  describe '#http_correlation_context_extractor, #rack_http_correlation_context_extractor' do
    it 'returns an instance of HttpTraceContextExtractor' do
      %i[http_correlation_context_extractor rack_http_correlation_context_extractor].each do |extractor_method|
        extractor = propagation.send(extractor_method)
        _(extractor).must_be_instance_of(
          OpenTelemetry::CorrelationContext::Propagation::HttpCorrelationContextExtractor
        )
      end
    end
  end

  describe '#http_correlation_context_injector, #rack_http_correlation_context_injector' do
    it 'returns an instance of HttpTraceContextInjector' do
      %i[http_correlation_context_injector rack_http_correlation_context_injector].each do |injector_method|
        injector = propagation.send(injector_method)
        _(injector).must_be_instance_of(
          OpenTelemetry::CorrelationContext::Propagation::HttpCorrelationContextInjector
        )
      end
    end
  end

  describe '#binary_format' do
    it 'returns an instance of BinaryFormat' do
      _(propagation.binary_format).must_be_instance_of(
        Trace::Propagation::BinaryFormat
      )
    end
  end
end
