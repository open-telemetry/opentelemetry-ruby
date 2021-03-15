# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    # No op implementation of Baggage::Builder
    class Builder
      def set_entry(key, value, metadata: nil); end

      def remove_entry(key); end

      def clear; end
    end
  end
end
