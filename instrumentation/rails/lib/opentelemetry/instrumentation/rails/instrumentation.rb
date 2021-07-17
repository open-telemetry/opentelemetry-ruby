# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module Rails
      # The Instrumentation class contains logic to detect and install the Rails
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          require_railtie
          patch_metal
        end

        present do
          defined?(::Rails)
        end

        option :enable_recognize_route, default: false, validate: :boolean

        private

        def require_dependencies
          require_relative 'patches/action_controller/metal'
        end

        def require_railtie
          require_relative 'railtie'
        end

        def patch_metal
          ::ActionController::Metal.prepend(Patches::ActionController::Metal)
        end
      end
    end
  end
end
