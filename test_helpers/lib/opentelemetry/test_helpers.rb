# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'

module OpenTelemetry
  # The TestHelpers module contains a collection of test helpers for the various
  # OpenTelemetry Ruby gems.
  module TestHelpers
    extend self
    NULL_LOGGER = Logger.new(File::NULL)

    # reset_opentelemetry is a test helper used to clear
    # SDK configuration state between calls
    def reset_opentelemetry
      OpenTelemetry.instance_variable_set(
        :@tracer_provider,
        OpenTelemetry::Internal::ProxyTracerProvider.new
      )

      # OpenTelemetry will load the defaults
      # on the next call to any of these methods
      OpenTelemetry.error_handler = nil
      OpenTelemetry.propagation = nil

      # We use a null logger to control the console
      # log output and explicitly enable it
      # when testing the log output
      OpenTelemetry.logger = NULL_LOGGER
    end

    def with_test_logger
      log_stream = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)
      yield log_stream
    ensure
      OpenTelemetry.logger = original_logger
    end

    def exportable_timestamp(time = Time.now)
      (time.to_r * 1_000_000_000).to_i
    end

    def with_env(new_env)
      env_to_reset = ENV.select { |k, _| new_env.key?(k) }
      keys_to_delete = new_env.keys - ENV.keys
      new_env.each_pair { |k, v| ENV[k] = v }
      yield
    ensure
      env_to_reset.each_pair { |k, v| ENV[k] = v }
      keys_to_delete.each { |k| ENV.delete(k) }
    end

    def with_ids(trace_id, span_id, &block)
      OpenTelemetry::Trace.stub(:generate_trace_id, trace_id) do
        OpenTelemetry::Trace.stub(:generate_span_id, span_id, &block)
      end
    end

    def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID,
                         total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp,
                         end_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp, attributes: nil, links: nil, events: nil, resource: nil,
                         instrumentation_scope: OpenTelemetry::SDK::InstrumentationScope.new('', 'v0.0.1'),
                         span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                         trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
      resource ||= OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
      OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, total_recorded_attributes,
                                              total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                              attributes, links, events, resource, instrumentation_scope, span_id, trace_id, trace_flags, tracestate)
    end

    def create_log_record_data(timestamp: OpenTelemetry::TestHelpers.exportable_timestamp,
                               observed_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp,
                               severity_text: nil,
                               severity_number: nil,
                               body: nil,
                               attributes: nil,
                               trace_id: OpenTelemetry::Trace.generate_trace_id,
                               span_id: OpenTelemetry::Trace.generate_span_id,
                               trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT,
                               resource: nil,
                               instrumentation_scope: OpenTelemetry::SDK::InstrumentationScope.new('', 'v0.0.1'),
                               total_recorded_attributes: 0)
      resource ||= OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
      OpenTelemetry::SDK::Logs::LogRecordData.new(
        timestamp,
        observed_timestamp,
        severity_text,
        severity_number,
        body,
        attributes,
        trace_id,
        span_id,
        trace_flags,
        resource,
        instrumentation_scope,
        total_recorded_attributes
      )
    end
  end
end
