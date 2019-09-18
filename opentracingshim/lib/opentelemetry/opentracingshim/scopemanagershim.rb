# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    class ScopeManagerShim < OpenTracing::ScopeManager
      def activate(span, finish_on_close: true)
        # TODO
      end

      def active
        # TODO
      end
    end
  end
end
