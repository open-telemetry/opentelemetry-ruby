# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # Contains operational implementations of the Baggage::Manager
  module Baggage
    # Read-only representation of a baggage entry
    class Entry
      attr_reader :value, :metadata

      def initialize(value, metadata = nil)
        @value = value
        @metadata = metadata
      end
    end
  end
end
