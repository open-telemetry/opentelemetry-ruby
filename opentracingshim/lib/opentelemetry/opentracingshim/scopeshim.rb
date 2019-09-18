# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    class ScopeShim < OpenTracing::Scope
      def span
        # TODO
        OpenTracing::Span::NOOP_INSTANCE
      end

      def close
        # TODO
      end
    end
  end
end
