# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module GraphQL
      # The Instrumentation class contains logic to detect and install the GraphQL instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |config|
          require_dependencies
          install_tracer(config)
        end

        present do
          defined?(::GraphQL)
        end

        ## Supported configuration keys for the install config hash:
        #
        # The enable_platform_field key expects a boolean value,
        # and enables the tracing of "execute_field" and "execute_field_lazy".
        #
        # The enable_platform_authorized key expects a boolean value,
        # and enables the tracing of "authorized" and "authorized_lazy".
        #
        # The enable_platform_resolve_type key expects a boolean value,
        # and enables the tracing of "resolve_type" and "resolve_type_lazy".
        #
        # The schemas key expects an array of Schemas, and is used to specify
        # which schemas are to be instrumented. If this value is not supplied
        # the default behaviour is to instrument all schemas.
        option :schemas,                      default: [],    validate: :array
        option :enable_platform_field,        default: false, validate: :boolean
        option :enable_platform_authorized,   default: false, validate: :boolean
        option :enable_platform_resolve_type, default: false, validate: :boolean

        private

        def require_dependencies
          require_relative 'tracers/graphql_tracer'
        end

        def install_tracer(config = {})
          if config[:schemas].empty?
            ::GraphQL::Schema.tracer(Tracers::GraphQLTracer.new)
          else
            config[:schemas].each do |schema|
              schema.use(Tracers::GraphQLTracer)
            rescue StandardError => e
              OpenTelemetry.logger.error("Unable to patch schema #{schema}: #{e.message}")
            end
          end
        end
      end
    end
  end
end
