# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Rack
      # The Adapter class contains logic to detect and install the Rack
      # instrumentation adapter
      class Adapter < OpenTelemetry::Instrumentation::Adapter
        install do |config|
          require_dependencies

          retain_middleware_names if config[:retain_middleware_names]
          configure_default_quantization
        end

        present do
          defined?(::Rack)
        end

        private

        def require_dependencies
          require_relative 'middlewares/tracer_middleware'
          require_relative 'util/quantization'
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

        def configure_default_quantization
          config[:url_quantization] ||= ->(url) { Util::Quantization.url(url, config[:quantization_options]) }
        end
      end
    end
  end
end

require_relative '../rack'
