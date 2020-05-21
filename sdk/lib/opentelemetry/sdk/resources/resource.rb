# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Resources
      # Resource represents a resource, which captures identifying information about the entities
      # for which telemetry (metrics or traces) is reported.
      class Resource
        class << self
          private :new # rubocop:disable Style/AccessModifierDeclarations

          # Returns a newly created {Resource} with the specified labels
          #
          # @param [Hash{String => String, Numeric, Boolean} labels Hash of key-value pairs to be used
          #   as labels for this resource
          # @raise [ArgumentError] If label keys and values are not strings
          # @return [Resource]
          def create(labels = {})
            frozen_labels = labels.each_with_object({}) do |(k, v), memo|
              raise ArgumentError, 'label keys must be strings' unless k.is_a?(String)
              raise ArgumentError, 'label values must be strings, integers, floats, or booleans' unless Internal.valid_value?(v)

              memo[-k] = v.freeze
            end.freeze

            new(frozen_labels)
          end

          def telemetry_sdk
            create(
              Constants::TELEMETRY_SDK_RESOURCE[:name] => 'opentelemetry',
              Constants::TELEMETRY_SDK_RESOURCE[:language] => 'ruby',
              Constants::TELEMETRY_SDK_RESOURCE[:version] => "semver:#{OpenTelemetry::SDK::VERSION}"
            )
          end
        end

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

        # Returns an enumerator for labels of this {Resource}
        #
        # @return [Enumerator]
        def label_enumerator
          @label_enumerator ||= labels.to_enum
        end

        # Returns a new, merged {Resource} by merging the current {Resource} with
        # the other {Resource}. In case of a collision, the current {Resource}
        # takes precedence
        #
        # @param [Resource] other The other resource to merge
        # @return [Resource] A new resource formed by merging the current resource
        #   with other
        def merge(other)
          return self unless other.is_a?(Resource)

          merged_labels = labels.merge(other.labels) do |_, old_v, new_v|
            old_v.empty? ? new_v : old_v
          end

          self.class.send(:new, merged_labels.freeze)
        end

        protected

        attr_reader :labels
      end
    end
  end
end
