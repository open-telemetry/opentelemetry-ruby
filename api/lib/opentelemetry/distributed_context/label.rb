# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    # A Label consists of key, value and Label::Metadata
    class Label
      attr_reader :metadata, :key, :value

      # Returns a new label
      #
      # @param [String] key The name of the label. Key along with Value can be
      #   used to aggregate and group stats, annotate traces and logs, etc. Must
      #   contain printable ASCII and a length between 0 and 256 (non-inclusive)
      # @param [String] value The value associated with key. Must contain
      #   printable ASCII.
      # @param [Metadata] metadata Properties associated with the label
      def initialize(key:, value:, metadata: Metadata::NO_PROPAGATION)
        raise ArgumentError unless Internal.printable_ascii?(key) && (1..255).include?(key.length)
        raise ArgumentError unless Internal.printable_ascii?(value)

        @key = -key
        @value = -value
        @metadata = metadata
      end

      # Label::Metadata contains properties associated with an Label. For now only the property hop_limit is defined.
      # In future, additional properties may be added to address specific situations.
      #
      # The creator of entries determines metadata of an entry it creates.
      class Metadata
        attr_reader :hop_limit

        # An @see Label with NO_PROPAGATION is considered to have local scope and is used within the process
        # where it is created.
        NO_PROPAGATION = 0

        # An @see Label with UNLIMITED_PROPAGATION can propagate unlimited hops. However, it is still subject
        # to outgoing and incoming (on remote side) filter criteria.
        UNLIMITED_PROPAGATION = -1

        def initialize(hop_limit)
          raise ArgumentError unless hop_limit.is_a?(Integer)

          @hop_limit = hop_limit
        end
      end
    end
  end
end
