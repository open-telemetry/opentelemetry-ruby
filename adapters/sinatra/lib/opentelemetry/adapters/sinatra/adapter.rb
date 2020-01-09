# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'sinatra'
require 'opentelemetry'

require_relative 'extensions/tracer_extension'

module OpenTelemetry
  module Adapters
    module Sinatra
      class Adapter
        class << self
          attr_reader :config,
                      :propagator

          def install(config = {})
            return :already_installed if installed?

            @config = config
            @propagator = OpenTelemetry.tracer_factory.http_text_format

            new.install
          end

          def tracer
            @tracer ||= OpenTelemetry.tracer_factory.tracer(
              Sinatra.name,
              Sinatra.version
            )
          end

          attr_accessor :installed
          alias_method :installed?, :installed
        end

        # @return [Symbol] indicating whether the method has already
        # been called or not (arbitrary, useful for testing purposes)
        def install
          return :already_installed if self.class.installed?
          self.class.installed = true

          register_tracer_extension

          :installed
        end

        private

        def register_tracer_extension
          ::Sinatra::Base.register Extensions::TracerExtension
        end
      end
    end
  end
end
