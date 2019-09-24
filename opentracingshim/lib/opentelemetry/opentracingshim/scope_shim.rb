# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    # Scope Shim provides a means of referencing an OTelemetry Context as
    # an OTracing scope
    class ScopeShim
      def span
        t = OpenTelemetry::Trace::Trace.new
        t.current_span
      end

      def close
        nil
      end
    end
  end
end
