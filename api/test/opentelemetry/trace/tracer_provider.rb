# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::TracerProvider do
  let(:tracer_provider) { OpenTelemetry::Trace::TracerProvider.new }

  describe '.tracer' do
    it 'returns the same tracer for the same arguments' do
      tracer1 = tracer_provider.tracer('component', '1.0')
      tracer2 = tracer_provider.tracer('component', '1.0')
      _(tracer1).must_equal(tracer2)
    end
  end
end
