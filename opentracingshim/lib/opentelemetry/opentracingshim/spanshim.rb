# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    class SpanShim < OpenTracing::Span
      NOOP_INSTANCE = Span.new.freeze

      def context
        # TODO
        SpanContext::NOOP_INSTANCE
      end

      def set_tag(key, value)
        # TODO
        self
      end

      def set_baggage_item(key, value)
        # TODO
        self
      end

      def get_baggage_item(key)
        # TODO
        nil
      end

      def log(event: nil, timestamp: Time.now, **fields)
        # TODO
        warn 'Span#log is deprecated.  Please use Span#log_kv instead.'
        nil
      end

      def log_kv(timestamp: Time.now, **fields)
        # TODO
        nil
      end

      def finish(end_time: Time.now)
        # TODO
        nil
      end
    end
  end
end
