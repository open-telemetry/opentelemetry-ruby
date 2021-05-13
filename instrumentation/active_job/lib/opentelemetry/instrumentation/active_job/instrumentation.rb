# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      # The Instrumentation class contains logic to detect and install the ActiveJob instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('5.2.0')

        install do |_config|
          require_dependencies
          patch_activejob
        end

        present do
          defined?(::ActiveJob)
        end

        compatible do
          Gem.loaded_specs['activejob'].version >= MINIMUM_VERSION
        end

        private

        def require_dependencies
          require_relative 'patches/base'
          require_relative 'patches/active_job_callbacks'
        end

        def patch_activejob
          ::ActiveJob::Base.prepend(Patches::Base)
          ::ActiveJob::Base.prepend(Patches::ActiveJobCallbacks)
        end
      end
    end
  end
end
