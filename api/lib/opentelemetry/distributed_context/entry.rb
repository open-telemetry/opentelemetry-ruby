# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    # An Entry consists of Entry::Metadata, Entry::Key, and Entry::Value.
    class Entry
      attr_reader :metadata, :key, :value

      # Entry::Key is the name of the Entry. Entry::Key along with Entry::Value can be used to aggregate and group stats,
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

      # Entry::Value wraps a string. It MUST contain only printable ASCII (codes between 32 and 126).
      class Value
        def initialize(value)
          raise ArgumentError unless Internal.printable_ascii?(value)

          @value = -value
        end

        def to_s
          @value
        end
      end

      # Entry::Metadata contains properties associated with an Entry. For now only the property entry_ttl is defined.
      # In future, additional properties may be added to address specific situations.
      #
      # The creator of entries determines metadata of an entry it creates.
      class Metadata
        attr_reader :entry_ttl

        # An @see Entry with NO_PROPAGATION is considered to have local scope and is used within the process
        # where it is created.
        NO_PROPAGATION = 0

        # An @see Entry with UNLIMITED_PROPAGATION can propagate unlimited hops. However, it is still subject
        # to outgoing and incoming (on remote side) filter criteria.
        UNLIMITED_PROPAGATION = -1

        def initialize(entry_ttl)
          raise ArgumentError unless entry_ttl.is_a?(Integer)

          @entry_ttl = entry_ttl
        end
      end
    end
  end
end
