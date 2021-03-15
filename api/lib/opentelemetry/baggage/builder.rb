# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    # SDK implementation of Baggage::Builder
    class Builder
      attr_reader :entries

      def initialize(entries)
        @entries = entries
      end

      # Set key-value in the to-be-created baggage
      #
      # @param [String] key The key to store this value under
      # @param [String] value String value to be stored under key
      def set_entry(key, value, metadata: nil)
        @entries[key] = OpenTelemetry::Baggage::Entry.new(value, metadata)
      end

      # Removes key from the to-be-created baggage
      #
      # @param [String] key The key to remove
      def remove_entry(key)
        @entries.delete(key)
      end

      # Clears all baggage from the to-be-created baggage
      def clear
        @entries.clear
      end
    end
  end
end
