# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      # The Instrumentation class contains logic to detect and install the ActionPack instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('5.2.0')

        install do |_config|
          require_railtie
          require_dependencies
          patch
        end

        present do
          defined?(::ActionController)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        option :enable_recognize_route, default: false, validate: :boolean

        private

        def gem_version
          Gem.loaded_specs['actionpack'].version
        end

        def patch
          ::ActionController::Metal.prepend(Patches::ActionController::Metal)
        end

        def require_dependencies
          require_relative 'patches/action_controller/metal'
        end

        def require_railtie
          require_relative 'railtie'
        end
      end
    end
  end
end
