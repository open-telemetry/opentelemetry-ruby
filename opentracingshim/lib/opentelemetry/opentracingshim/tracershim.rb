# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    class TracerShim < OpenTracing::Tracer
      attr_reader :scope_manager

      def initialize(tracer)
        @tracer = tracer
        @scope_manager = ScopeManagerShim.new tracer
      end

      def active_span
        super
        scope.span if scope_manager.active
      end

      def start_active_span(operation_name,
                            child_of: nil,
                            references: nil,
                            start_time: Time.now,
                            tags: nil,
                            ignore_active_scope: false,
                            finish_on_close: true)
        # TODO
      end

      def start_span(operation_name,
                     child_of: nil,
                     references: nil,
                     start_time: Time.now,
                     tags: nil,
                     ignore_active_scope: false)
        # TODO
      end

      def inject(span_context, format, carrier)
        # TODO
      end

      def extract(format, carrier)
        # TODO
      end
    end
  end
end
