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
      def initialize(raw_labels = {})
        @labels = check_and_freeze_labels(raw_labels)
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

      private

      def check_and_freeze_labels(raw_labels)
        raw_labels.each_with_object({}) do |(k, v), memo|
          raise ArgumentError, 'label keys and values must be strings' unless k.is_a?(String) && v.is_a?(String)

          memo[-k] = -v
        end.freeze
      end
    end
  end
end
