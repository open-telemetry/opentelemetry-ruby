# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::B3::Multi do
  describe '#text_map_propagator' do
    it 'returns an instance of TextMapPropagator' do
      propagator = OpenTelemetry::Propagator::B3::Multi.text_map_propagator
      _(propagator).must_be_instance_of(
        OpenTelemetry::Propagator::B3::Multi::TextMapPropagator
      )
    end
  end
end
