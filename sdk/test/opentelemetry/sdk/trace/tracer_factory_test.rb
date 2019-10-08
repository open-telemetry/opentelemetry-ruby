# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::TracerFactory do
  let(:tracer_factory) { OpenTelemetry::SDK::Trace::TracerFactory.new }

  describe '.tracer' do
    it 'returns the same tracer for the same arguments' do
      tracer1 = tracer_factory.tracer('component', 'semver:1.0')
      tracer2 = tracer_factory.tracer('component', 'semver:1.0')
      _(tracer1).must_equal(tracer2)
    end

    it 'returns a default name-less version-less tracer' do
      tracer = tracer_factory.tracer
      _(tracer.name).must_equal('')
      _(tracer.version).must_equal('')
    end

    it 'returns different tracers for different names' do
      tracer1 = tracer_factory.tracer('component1', 'semver:1.0')
      tracer2 = tracer_factory.tracer('component2', 'semver:1.0')
      _(tracer1).wont_equal(tracer2)
    end

    it 'returns different tracers for different versions' do
      tracer1 = tracer_factory.tracer('component', 'semver:1.0')
      tracer2 = tracer_factory.tracer('component', 'semver:2.0')
      _(tracer1).wont_equal(tracer2)
    end
  end
end
