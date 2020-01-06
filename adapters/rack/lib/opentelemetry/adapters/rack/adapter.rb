# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Rack
      class Adapter
        class << self
          attr_reader :config,
                      :propagator

          def install(config = {})
            @config = config
            @propagator = OpenTelemetry.tracer_factory.http_text_format

            new.install
          end

          def tracer
            @tracer ||= OpenTelemetry::tracer_factory.tracer(
              Rack.name,
              Rack.version
            )
          end

          attr_accessor :installed
          alias_method :installed?, :installed
        end

        def install
          return :already_installed if self.class.installed?

          require_relative 'middlewares/tracer_middleware'

          retain_middleware_names if config[:retain_middleware_names]

          self.class.installed = true
        end

        private

        MissingApplicationError = Class.new(StandardError)

        def config
          self.class.config
        end

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

require_relative '../rack'
