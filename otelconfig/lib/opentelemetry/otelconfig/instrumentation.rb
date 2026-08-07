# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # OtelConfig module — instrumentation configuration helpers.
  module OtelConfig
    class << self
      # Installs instrumentation libraries from the registry.
      def configure_instrumentation(instrumentation_cfg)
        config_map = build_instrumentation_config_map(instrumentation_cfg)
        OpenTelemetry::Instrumentation.registry.install_all(config_map)
        config_map
      rescue NameError
        OpenTelemetry.logger.warn('opentelemetry-instrumentation-all not available; skipping instrumentation install.')
      end

      # Transforms the YAML instrumentation config into the flat hash that
      # install_all expects: { 'OpenTelemetry::Instrumentation::Foo' => { opt: val } }
      #
      # Accepts either the schema-generated ExperimentalInstrumentation struct
      # (reading its +ruby+ language map) or a raw Hash with a 'ruby' key.
      def build_instrumentation_config_map(instrumentation_cfg)
        ruby_instrumentation =
          if instrumentation_cfg.is_a?(Hash)
            instrumentation_cfg['ruby']
          elsif instrumentation_cfg.respond_to?(:ruby)
            instrumentation_cfg.ruby
          end
        return {} unless ruby_instrumentation.is_a?(Hash)

        name_map = build_instrumentation_name_map
        ruby_instrumentation.each_with_object({}) do |(short_name, options), result|
          full_name = name_map[short_name.to_s]
          unless full_name
            OpenTelemetry.logger.warn("Declarative config: unknown instrumentation short name '#{short_name}' — skipping.")
            next
          end
          result[full_name] = options.is_a?(Hash) ? options.transform_keys(&:to_sym) : {}
        end
      end

      # Builds a lookup table: snake_case_short_name => full_class_name
      # e.g. 'net_http' => 'OpenTelemetry::Instrumentation::Net::HTTP'
      def build_instrumentation_name_map
        registry = OpenTelemetry::Instrumentation.registry
        registry.instance_variable_get(:@instrumentation).each_with_object({}) do |inst_class, map|
          inst = inst_class.instance
          short = inst.name.delete_prefix('OpenTelemetry::Instrumentation::')
                      .gsub('::', '_')
                      .gsub(/([a-z\d])([A-Z])/, '\1_\2') # this is for case like AwsLambda -> aws_lambda
                      .downcase
          map[short] = inst.name
        end
      rescue StandardError
        {}
      end
    end
  end
end
