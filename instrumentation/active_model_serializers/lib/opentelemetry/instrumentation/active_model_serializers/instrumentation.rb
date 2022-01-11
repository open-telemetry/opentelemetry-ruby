# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveModelSerializers
      # Instrumentation class that detects and installs the ActiveModelSerializers instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('0.10.0')

        install do |_config|
          require_dependencies
          register_event_handler
        end

        present do
          !defined?(::ActiveModelSerializers).nil?
        end

        compatible do
          !defined?(::ActiveSupport::Notifications).nil? && gem_version >= MINIMUM_VERSION
        end

        private

        def gem_version
          Gem.loaded_specs['active_model_serializers'].version
        end

        def require_dependencies
          require_relative 'event_handler'
        end

        def register_event_handler
          ::ActiveSupport::Notifications.subscribe(event_name) do |_name, start, finish, _id, payload|
            EventHandler.handle(start, finish, payload)
          end
        end

        def event_name
          'render.active_model_serializers'
        end
      end
    end
  end
end
