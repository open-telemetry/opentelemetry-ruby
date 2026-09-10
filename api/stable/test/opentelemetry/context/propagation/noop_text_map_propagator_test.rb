# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context::Propagation::NoopTextMapPropagator do
  describe '#extract' do
    it 'returns the original context' do
      context = OpenTelemetry::Context.empty.set_value('k1', 'v1')
      propagator = OpenTelemetry::Context::Propagation::NoopTextMapPropagator.new
      result = propagator.extract({ 'foo' => 'bar' }, context: context)
      _(result).must_equal(context)
    end
  end

  describe '#inject' do
    it 'does not modify the carrier' do
      context = OpenTelemetry::Context.empty.set_value('k1', 'v1')
      propagator = OpenTelemetry::Context::Propagation::NoopTextMapPropagator.new
      carrier = {}
      propagator.inject(carrier, context: context)
      _(carrier).must_equal({})
    end
  end
end
