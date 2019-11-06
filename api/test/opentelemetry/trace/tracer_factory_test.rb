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

  describe '#binary_format' do
    it 'returns an instance of BinaryFormat' do
      _(tracer_factory.binary_format).must_be_instance_of(
        Propagation::BinaryFormat
      )
    end
  end

  describe '#http_text_format' do
    it 'returns a formatter for lowercase trace context keys' do
      formatter = tracer_factory.http_text_format
      _(formatter).must_be_instance_of(
        Propagation::TextFormat
      )
      _(formatter.fields).must_equal(%w[traceparent tracestate])
    end
  end

  describe '#rack_http_text_format' do
    it 'returns a formatter for Rack normalized trace context keys' do
      formatter = tracer_factory.rack_http_text_format
      _(formatter).must_be_instance_of(
        Propagation::TextFormat
      )
      _(formatter.fields).must_equal(%w[HTTP_TRACEPARENT HTTP_TRACESTATE])
    end
  end
end
