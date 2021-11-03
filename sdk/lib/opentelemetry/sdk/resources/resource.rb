# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
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

          # Returns a newly created {Resource} with the specified attributes
          #
          # @param [Hash{String => String, Numeric, Boolean}] attributes Hash of key-value pairs to be used
          #   as attributes for this resource
          # @param [optional String] schema_url Resource schema_url of the application's emitted telemetry
          # @raise [ArgumentError] If attribute keys and values are not strings
          # @return [Resource]
          def create(attributes = {}, schema_url = nil)
            frozen_attributes = attributes.each_with_object({}) do |(k, v), memo|
              raise ArgumentError, 'attribute keys must be strings' unless k.is_a?(String)
              raise ArgumentError, 'attribute values must be (array of) strings, integers, floats, or booleans' unless Internal.valid_value?(v)

              memo[-k] = v.freeze
            end.freeze

            raise ArgumentError, 'schema_url must be a string' unless schema_url.nil? || schema_url.is_a?(String)

            new(frozen_attributes, schema_url.freeze)
          end

          def default
            @default ||= create(SemanticConventions::Resource::SERVICE_NAME => 'unknown_service').merge(process).merge(telemetry_sdk).merge(service_name_from_env)
          end

          def telemetry_sdk
            resource_attributes = {
              SemanticConventions::Resource::TELEMETRY_SDK_NAME => 'opentelemetry',
              SemanticConventions::Resource::TELEMETRY_SDK_LANGUAGE => 'ruby',
              SemanticConventions::Resource::TELEMETRY_SDK_VERSION => OpenTelemetry::SDK::VERSION
            }

            resource_pairs = ENV['OTEL_RESOURCE_ATTRIBUTES']

            return create(resource_attributes) unless resource_pairs.is_a?(String)

            resource_pairs.split(',').each do |pair|
              key, value = pair.split('=')
              resource_attributes[key] = value
            end

            resource_attributes.delete_if { |_key, value| value.nil? || value.empty? }
            create(resource_attributes)
          end

          def process
            resource_attributes = {
              SemanticConventions::Resource::PROCESS_PID => Process.pid,
              SemanticConventions::Resource::PROCESS_COMMAND => $PROGRAM_NAME,
              SemanticConventions::Resource::PROCESS_RUNTIME_NAME => RUBY_ENGINE,
              SemanticConventions::Resource::PROCESS_RUNTIME_VERSION => RUBY_VERSION,
              SemanticConventions::Resource::PROCESS_RUNTIME_DESCRIPTION => RUBY_DESCRIPTION
            }

            create(resource_attributes)
          end

          private

          def service_name_from_env
            service_name = ENV['OTEL_SERVICE_NAME']
            create({ SemanticConventions::Resource::SERVICE_NAME => service_name }, "https://opentelemetry.io/schemas/#{SemanticConventions::VERSION}") unless service_name.nil?
          end
        end

        # @api private
        # The constructor is private and only for use internally by the class.
        # Users should use the {create} factory method to obtain a {Resource}
        # instance.
        #
        # @param [Hash<String, String>] frozen_attributes Frozen-hash of frozen-string
        #  key-value pairs to be used as attributes for this resource
        # @param [String] schema_url Resource schema_url of the application's emitted telemetry
        # @return [Resource]
        def initialize(frozen_attributes, schema_url)
          @attributes = frozen_attributes
          @schema_url = schema_url
        end

        # Returns an enumerator for attributes of this {Resource}
        #
        # @return [Enumerator]
        def attribute_enumerator
          @attribute_enumerator ||= attributes.to_enum
        end

        # Returns a new, merged {Resource} by merging the current {Resource} with
        # the other {Resource}. In case of a collision, the current {Resource}
        # takes precedence
        #
        # @param [Resource] other The other resource to merge
        # @return [Resource] A new resource formed by merging the current resource
        #   with other
        def merge(other) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          return self unless other.is_a?(Resource)

          # Order of merge operations defined by Specification
          # https://github.com/open-telemetry/opentelemetry-specification/blob/49c2f56f3c0468ceb2b69518bcadadd96e0a5a8b/specification/resource/sdk.md#merge
          merged_schema_url = if schema_url.nil? || schema_url.empty?
                                other.schema_url
                              elsif other.schema_url.nil? || other.schema_url.empty?
                                schema_url
                              elsif schema_url == other.schema_url
                                schema_url
                              else
                                OpenTelemetry.logger.error("Failed to merge resources: The two schemas #{schema_url} and #{other.schema_url} are incompatible")
                                return self
                              end

          merged_attributes = attributes.merge(other.attributes).freeze

          self.class.send(:new, merged_attributes, merged_schema_url)
        end

        attr_reader :schema_url

        protected

        attr_reader :attributes
      end
    end
  end
end
