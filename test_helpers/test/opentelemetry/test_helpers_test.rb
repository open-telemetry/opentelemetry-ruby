# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::TestHelpers do
  describe '.reset_opentelemetry' do
    it 'sets OpenTelemetry back to default values' do
      # Assert the
      _(OpenTelemetry.tracer_provider).must_be_instance_of(OpenTelemetry::Internal::ProxyTracerProvider)
      _(OpenTelemetry.propagation).must_be_instance_of(OpenTelemetry::Context::Propagation::NoopTextMapPropagator)

      OpenTelemetry::SDK.configure

      expected_propagators = [
        OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator,
        OpenTelemetry::Baggage::Propagation.text_map_propagator
      ]
      _(OpenTelemetry.propagation.instance_variable_get(:@propagators)).must_equal(expected_propagators)
      _(OpenTelemetry.tracer_provider).must_be_instance_of(OpenTelemetry::SDK::Trace::TracerProvider)

      OpenTelemetry::TestHelpers.reset_opentelemetry

      _(OpenTelemetry.tracer_provider).must_be_instance_of(OpenTelemetry::Internal::ProxyTracerProvider)
      _(OpenTelemetry.propagation).must_be_instance_of(OpenTelemetry::Context::Propagation::NoopTextMapPropagator)
      _(OpenTelemetry.logger).must_equal(OpenTelemetry::TestHelpers::NULL_LOGGER)
    end
  end

  describe '.with_test_logger' do
    it 'temporarily captures log output for inspection' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        OpenTelemetry.logger.warn('danger, danger')
        _(log_stream.string).must_match(/danger, danger/)
      end
    end
  end
end
