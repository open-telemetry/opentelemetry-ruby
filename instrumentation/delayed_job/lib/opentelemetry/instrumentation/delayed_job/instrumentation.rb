# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module DelayedJob
      # Instrumentation class that detects and installs the DelayedJob instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('4.1')

        install do |_config|
          require_dependencies
          register_tracer_plugin
        end

        present do
          !defined?(::Delayed).nil?
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        private

        def gem_version
          Gem.loaded_specs['delayed_job'].version
        end

        def require_dependencies
          require_relative 'plugins/tracer_plugin'
        end

        def register_tracer_plugin
          ::Delayed::Worker.plugins << Plugins::TracerPlugin
        end
      end
    end
  end
end
