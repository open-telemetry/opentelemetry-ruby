# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    # An immutable implementation of the DistributedContext that does not contain any entries.
    class DistributedContext
      EMPTY_ENTRIES = [].freeze

      private_constant(:EMPTY_ENTRIES)

      def entries
        EMPTY_ENTRIES
      end

      def [](_key)
        nil
      end
    end
  end
end
