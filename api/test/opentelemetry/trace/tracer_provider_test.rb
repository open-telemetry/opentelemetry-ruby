# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::TracerProvider do
  let(:tracer_provider) { OpenTelemetry::Trace::TracerProvider.new }

  describe '.tracer' do
    # Legacy positional calling conventions
    it 'returns a tracer with no arguments' do
      tracer = tracer_provider.tracer
      _(tracer).must_be_instance_of(OpenTelemetry::Trace::Tracer)
    end

    it 'returns a tracer with name only' do
      tracer = tracer_provider.tracer('component')
      _(tracer).must_be_instance_of(OpenTelemetry::Trace::Tracer)
    end

    it 'returns the same tracer for the same positional arguments' do
      tracer1 = tracer_provider.tracer('component', '1.0')
      tracer2 = tracer_provider.tracer('component', '1.0')
      _(tracer1).must_equal(tracer2)
    end

    # Keyword calling conventions
    it 'accepts all keyword arguments' do
      tracer = tracer_provider.tracer(name: 'component', version: '1.0', attributes: { 'key' => 'value' })
      _(tracer).must_be_instance_of(OpenTelemetry::Trace::Tracer)
    end

    it 'accepts name keyword only' do
      tracer = tracer_provider.tracer(name: 'component')
      _(tracer).must_be_instance_of(OpenTelemetry::Trace::Tracer)
    end

    # Mixed positional + keyword
    it 'accepts positional arguments with attributes keyword' do
      tracer = tracer_provider.tracer('component', '1.0', attributes: { 'key' => 'value' })
      _(tracer).must_be_instance_of(OpenTelemetry::Trace::Tracer)
    end

    # Nil attributes equivalence
    it 'returns the same tracer without attributes' do
      tracer1 = tracer_provider.tracer('component', '1.0')
      tracer2 = tracer_provider.tracer('component', '1.0', attributes: nil)
      _(tracer1).must_equal(tracer2)
    end
  end
end
