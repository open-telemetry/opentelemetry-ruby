# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    # An immutable implementation of the DistributedContext that does not contain any entries.
    class DistributedContext
      def entries
        []
      end

      def [](_key)
        nil
      end
    end
  end
end
