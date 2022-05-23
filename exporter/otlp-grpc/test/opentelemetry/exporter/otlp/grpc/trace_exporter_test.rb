# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE

  describe '#exporter' do
    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      span_data = OpenTelemetry::TestHelpers.create_span_data
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end
  end
end
