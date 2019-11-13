# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    # A Label consists of Label::Metadata, Label::Key, and Label::Value.
    class Label
      attr_reader :metadata, :key, :value

      # Returns a new label
      #
      # @param [Key] key The name of the label
      # @param [Value] value The value associated with key
      # @param [Metadata] metadata Properties associated with the label
      def initialize(key:, value:, metadata: Metadata::NO_PROPAGATION)
        @key = key
        @value = value
        @metadata = metadata
      end

      # Label::Key is the name of the Label. Label::Key along with Label::Value can be used to aggregate and group stats,
      # annotate traces and logs, etc.
      #
      # Restrictions
      # - Must contain only printable ASCII (codes between 32 and 126 inclusive)
      # - Must have length greater than zero and less than 256.
      # - Must not be empty.
      class Key
        attr_reader :name

        def initialize(name)
          raise ArgumentError unless Internal.printable_ascii?(name) && (1..255).include?(name.length)

          @name = -name
        end
      end

      # Label::Value wraps a string. It MUST contain only printable ASCII (codes between 32 and 126).
      class Value
        def initialize(value)
          raise ArgumentError unless Internal.printable_ascii?(value)

          @value = -value
        end

        def to_s
          @value
        end
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
