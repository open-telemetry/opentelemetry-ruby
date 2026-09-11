# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TraceContext do
  describe '#text_map_propagator' do
    it 'returns an instance of TextMapPropagator' do
      propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
      _(propagator).must_be_instance_of(
        OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator
      )
    end
  end
end
