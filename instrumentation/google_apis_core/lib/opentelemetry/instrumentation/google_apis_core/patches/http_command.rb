# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GoogleApisCore
      module Patches
        # Module to prepend to ::Google::Apis::Core::HttpCommand for instrumentation
        module HttpCommand
          def opencensus_begin_span
            return if @opentelemetry_tracing_span
            return unless OpenTelemetry::Trace.current_span.recording?

            attributes = {
              'http.host' => url.host.to_s,
              'http.method' => method.to_s,
              'http.target' => url.path.to_s,
              'peer.service' => 'google'
            }

            @opentelemetry_tracing_span = tracer.start_span(url.host.to_s, attributes: attributes)
          rescue StandardError # rubocop:disable Lint/HandleExceptions
          end

          def opencensus_end_span
            return unless @opentelemetry_tracing_span
            return unless OpenTelemetry::Trace.current_span.recording?

            if @http_res
              status_code = @http_res.status.to_i
              @opentelemetry_tracing_span['http.status_code'] = status_code
              @opentelemetry_tracing_span.status = OpenTelemetry::Trace::Status.http_to_status(
                status_code
              )
            end

            @opentelemetry_tracing_span.finish
            @opentelemetry_tracing_span = nil
          rescue StandardError # rubocop:disable Lint/HandleExceptions
          end

          private

          def tracer
            GoogleApisCore::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
