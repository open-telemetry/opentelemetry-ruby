# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveModelSerializers
      # Instrumentation class that detects and installs the ActiveModelSerializers instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('2.5.0')

        install do |_config|
          require_dependencies
          register_subscriber
        end

        present do
          !defined?(::ActiveModelSerializers::Monitoring::Global).nil? && gem_version >= MINIMUM_VERSION
        end

        private

        def gem_version
          Gem.loaded_specs['active_model_serializers']&.version
        end

        def require_dependencies
          require_relative 'subscriber'
        end

        def register_subscriber
          # Subscribe to all COMMAND queries with our subscriber class
          ::ActiveModelSerializers::Monitoring::Global.subscribe(::ActiveModelSerializers::Monitoring::COMMAND, Subscriber.new)
        end
      end
    end
  end
end
