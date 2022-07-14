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
          # @param [String] Specifies the Schema URL that should be recorded in the emitted resource.
          # @raise [ArgumentError] If attribute keys and values are not strings
          # @raise [ArgumentError] If the schema URL is given but it is not a string.
          # @return [Resource]
          def create(attributes = {}, schema_url: nil)
            raise ArgumentError, 'If given, schema url must be a string' unless schema_url.nil? || schema_url.is_a?(String)

            frozen_attributes = attributes.each_with_object({}) do |(k, v), memo|
              raise ArgumentError, 'attribute keys must be strings' unless k.is_a?(String)
              raise ArgumentError, 'attribute values must be (array of) strings, integers, floats, or booleans' unless Internal.valid_value?(v)

              memo[-k] = v.freeze
            end.freeze

            new(frozen_attributes, schema_url.freeze)
          end

          def default
            @default ||= create({ SemanticConventions::Resource::SERVICE_NAME => 'unknown_service' }).merge(process).merge(telemetry_sdk).merge(service_name_from_env)
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
            create({ SemanticConventions::Resource::SERVICE_NAME => service_name }) unless service_name.nil?
          end
        end

        # @api private
        # The constructor is private and only for use internally by the class.
        # Users should use the {create} factory method to obtain a {Resource}
        # instance.
        #
        # @param [Hash<String, String>] frozen_attributes Frozen-hash of frozen-string
        #  key-value pairs to be used as attributes for this resource
        # @param [String] frozen_schema_url Frozen schema URL for this resource
        # @return [Resource]
        def initialize(frozen_attributes, frozen_schema_url)
          @attributes = frozen_attributes
          @schema_url = frozen_schema_url
        end

        # Returns an enumerator for attributes of this {Resource}
        #
        # @return [Enumerator]
        def attribute_enumerator
          @attribute_enumerator ||= attributes.to_enum
        end

        # Returns a new, merged {Resource} by merging the current {Resource} with
        # the other {Resource}. In case of an attributes collision, the other {Resource}
        # takes precedence. If two incompatible schema urls are given, then the schema
        # URL of the resulting resource will be unset.
        #
        # @param [Resource] other The other resource to merge
        # @return [Resource] A new resource formed by merging the current resource
        #   with other
        def merge(other)
          return self unless other.is_a?(Resource)

          # This is slightly verbose, but tries to follow the definition in the spec closely.
          new_schema_url = if schema_url.nil?
                             other.schema_url
                           elsif other.schema_url.nil? || schema_url == other.schema_url
                             schema_url
                           else
                             # According to the spec: The resulting resource is undefined, and its contents are implementation-specific.
                             # We choose to simply un-set the resource URL and log a warning about it, and allow the attributes to merge.
                             OpenTelemetry.logger.warn(
                               "Merging resources with schema version '#{schema_url}' and '#{other.schema_url}' is undefined."
                             )

                             nil
                           end

          self.class.send(:new, attributes.merge(other.attributes).freeze, new_schema_url.freeze)
        end

        attr_reader :schema_url

        protected

        attr_reader :attributes
      end
    end
  end
end
