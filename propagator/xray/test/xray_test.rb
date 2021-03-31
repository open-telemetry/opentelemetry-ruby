# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::XRay do
  describe '#text_map_propagator' do
    it 'returns an instance of TextMapPropagator' do
      propagator = OpenTelemetry::Propagator::XRay.text_map_propagator
      _(propagator).must_be_instance_of(
        OpenTelemetry::Propagator::XRay::TextMapPropagator
      )
    end
  end
end
