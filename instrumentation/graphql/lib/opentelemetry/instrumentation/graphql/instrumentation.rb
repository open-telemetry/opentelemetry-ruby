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

        private

        def require_dependencies
          require_relative 'tracers/graphql_tracer'
        end

        def install_tracer(config = {})
          if config[:schemas].nil? || config[:schemas].empty?
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
