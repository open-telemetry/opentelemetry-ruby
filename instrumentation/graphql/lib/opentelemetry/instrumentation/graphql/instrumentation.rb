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
        install do |_config|
          require_dependencies
          install_tracer
        end

        present do
          defined?(::GraphQL)
        end

        private

        def require_dependencies
          require_relative 'tracers/graphql_tracer'
        end

        def install_tracer
          ::GraphQL::Schema.tracer(Tracers::GraphQLTracer.new)
        end
      end
    end
  end
end
