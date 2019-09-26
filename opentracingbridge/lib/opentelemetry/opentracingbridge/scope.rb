# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingBridge
    # Scope provides a means of referencing an OTelemetry Tracer's Context as
    # an OTracing scope
    class Scope < OpenTracing::Scope
      def initialize(tracer = nil)
        @tracer = tracer || OpenTelemetry::Trace::Tracer.new
      end

      def span
        @tracer.current_span
      end

      def close
        @tracer.current_span.finish
      end
    end
  end
end
