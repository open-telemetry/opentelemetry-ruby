# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module Rack
      # The Instrumentation class contains logic to detect and install the Rack
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |config|
          require_dependencies

          retain_middleware_names if config[:retain_middleware_names]
        end

        present do
          defined?(::Rack)
        end

        option :allowed_request_headers,  default: [],    validate: :array
        option :allowed_response_headers, default: [],    validate: :array
        option :application,              default: nil,   validate: :callable
        option :record_frontend_span,     default: false, validate: :boolean
        option :retain_middleware_names,  default: false, validate: :boolean
        option :untraced_endpoints,       default: [],    validate: :array
        option :url_quantization,         default: nil,   validate: :callable
        option :untraced_requests,        default: nil,   validate: :callable

        private

        def require_dependencies
          require_relative 'middlewares/tracer_middleware'
        end

        MissingApplicationError = Class.new(StandardError)

        # intercept all middleware-compatible calls, retain class name
        def retain_middleware_names
          next_middleware = config[:application]
          raise MissingApplicationError unless next_middleware

          while next_middleware
            if next_middleware.respond_to?(:call)
              next_middleware.singleton_class.class_eval do
                alias_method :__call, :call

                def call(env)
                  env['RESPONSE_MIDDLEWARE'] = self.class.to_s
                  __call(env)
                end
              end
            end

            next_middleware = next_middleware.instance_variable_defined?('@app') &&
                              next_middleware.instance_variable_get('@app')
          end
        end
      end
    end
  end
end
