# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation do
  describe '#text_map_propagator' do
    it 'returns an instance of TextMapPropagator' do
      propagator = OpenTelemetry::Baggage::Propagation.text_map_propagator
      _(propagator).must_be_instance_of(
        OpenTelemetry::Baggage::Propagation::TextMapPropagator
      )
    end
  end
end
