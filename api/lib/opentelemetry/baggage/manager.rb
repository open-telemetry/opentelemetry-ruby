# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    # No op implementation of BaggageManager
    class Manager
      def set_value(context, key, value)
        context
      end

      def value(context, key)
        nil
      end

      def remove_value(context, key)
        context
      end

      def clear(context)
        context
      end

      def http_injector
        nil
      end

      def http_extractor
        nil
      end
    end
  end
end
