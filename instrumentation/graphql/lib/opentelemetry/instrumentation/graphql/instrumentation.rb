# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GraphQL
      # The Instrumentation class contains logic to detect and install the GraphQL
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |config|
          require_dependencies
          patch_graphql(config)
        end

        present do
          defined?(::GraphQL)
        end

        private

        def require_dependencies
          require_relative 'patches/opentelemetry_graphql_tracing'
        end

        def patch_graphql(config = {})
          config[:schemas].each { |s| patch_schema!(s) }
        end

        def target_version
          Integration.version
        end

        def patch_schema!(schema)
          if schema.respond_to?(:use)
            schema.use(
              OpenTelemetry::Instrumentation::GraphQL::Patches::OpenTelemetryGraphQLTracing
            )
          else
            schema.define do
              use(
                OpenTelemetry::Instrumentation::GraphQL::Patches::OpenTelemetryGraphQLTracing
              )
            end
          end
        # Protect our instrumentation from bad user input in schema config option
        rescue StandardError => e
          OpenTelemetry.logger.error("Unable to patch schema #{schema}: #{e.message}")
          true
        end
      end
    end
  end
end
