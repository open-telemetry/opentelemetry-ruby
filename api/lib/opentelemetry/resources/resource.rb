# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resources
    # Resource represents a resource, which captures identifying information about the entities
    # for which telemetry (metrics or traces) is reported.
    class Resource
      attr_reader :labels

      def initialize(kvs)
        # TODO: how defensive should we be here?
        @labels = kvs.each_with_object({}) do |(k, v), memo|
          memo[-k] = -v
        end
      end

      def merge(other)
        raise ArgumentError unless other.is_a?(Resource)

        merged_labels = \
          other.labels.each_with_object(labels.dup) do |(k, v), memo|
            next if (current = memo[k]) && !current.empty?

            memo[k] = v
          end

        self.class.new(merged_labels)
      end
    end
  end
end
