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
          require_relative 'patches/active_job_callbacks'
          ::ActiveJob::Base.prepend(Patches::ActiveJobCallbacks)
        end

        present do
          defined?(::ActiveJob)
        end

        compatible do
          Gem.loaded_specs['activejob'].version >= MINIMUM_VERSION
        end
      end
    end
  end
end
