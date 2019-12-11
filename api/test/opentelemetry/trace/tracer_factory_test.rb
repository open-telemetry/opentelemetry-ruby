# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::TracerFactory do
  let(:tracer_factory) { OpenTelemetry::Trace::TracerFactory.new }

  describe '.tracer' do
    it 'returns the same tracer for the same arguments' do
      tracer1 = tracer_factory.tracer('component', 'semver:1.0')
      tracer2 = tracer_factory.tracer('component', 'semver:1.0')
      _(tracer1).must_equal(tracer2)
    end
  end

  describe '#http_extractor, #rack_http_extractor' do
    it 'returns an instance of HttpTraceContextExtractor' do
      %i[http_extractor rack_http_extractor].each do |extractor_method|
        extractor = tracer_factory.send(extractor_method)
        _(extractor).must_be_instance_of(
          Propagation::HttpTraceContextExtractor
        )
      end
    end
  end

  describe '#http_injector, #rack_http_injector' do
    it 'returns an instance of HttpTraceContextInjector' do
      %i[http_injector rack_http_injector].each do |injector_method|
        injector = tracer_factory.send(injector_method)
        _(injector).must_be_instance_of(
          Propagation::HttpTraceContextInjector
        )
      end
    end
  end

  describe '#binary_format' do
    it 'returns an instance of BinaryFormat' do
      _(tracer_factory.binary_format).must_be_instance_of(
        Propagation::BinaryFormat
      )
    end
  end
end
