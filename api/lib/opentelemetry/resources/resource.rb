# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resources
    # Resource represents a resource, which captures identifying information about the entities
    # for which telemetry (metrics or traces) is reported.
    class Resource
      # Returns the labels for this {Resource}
      #
      # @return [Hash<String, String>]
      attr_reader :labels

      # Returns a newly created {Resource} with the specified labels
      #
      # @param [Hash<String, String>] kvs Hash of key-value pairs to be used
      #   as labels for this resource
      # @return [Resource]
      def initialize(kvs)
        # TODO: how defensive should we be here?
        @labels = kvs.each_with_object({}) do |(k, v), memo|
          memo[-k] = -v
        end
      end

      # Returns a new, merged {Resource} by merging the current {Resource} with
      # the other {Resource}. In case of a collision, the current {Resource}
      # takes precedence
      #
      # @param [Resource] other The other resource to merge
      # @return [Resource] A new resource formed by merging the current resource
      #   with other
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
