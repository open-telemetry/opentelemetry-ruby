# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resources
    # Resource represents a resource, which captures identifying information about the entities
    # for which telemetry (metrics or traces) is reported.
    class Resource
      class << self
        private :new # rubocop:disable Style/AccessModifierDeclarations

        # Returns a newly created {Resource} with the specified labels
        #
        # @param [Hash<String, String>] labels Hash of key-value pairs to be used
        #   as labels for this resource
        # @raise [ArgumentError] If label keys and values are not strings
        # @return [Resource]
        def create(labels = {})
          new(check_and_freeze_labels(labels))
        end

        private

        def check_and_freeze_labels(labels)
          labels.each_with_object({}) do |(k, v), memo|
            raise ArgumentError, 'label keys and values must be strings' unless k.is_a?(String) && v.is_a?(String)

            memo[-k] = -v
          end.freeze
        end
      end
      # Returns the labels for this {Resource}
      #
      # @return [Hash<String, String>]
      attr_reader :labels

      # @api private
      # The constructor is private and only for use internally by the class.
      # Users should use the {create} factory method to obtain a {Resource}
      # instance.
      #
      # @param [Hash<String, String>] frozen_labels Frozen-hash of frozen-string
      #  key-value pairs to be used as labels for this resource
      # @return [Resource]
      def initialize(frozen_labels)
        @labels = frozen_labels
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

        merged_labels = labels.merge(other.labels) do |_, old_v, new_v|
          old_v.empty? ? new_v : old_v
        end

        self.class.send(:new, merged_labels.freeze)
      end
    end
  end
end
