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

        ## Supported configuration keys for the install config hash:
        #
        # The context_propgation key expects a hash of "JobClass" => propgation_option.
        # When an ActiveJob is executed, the propagation_option will be consulted
        # to determine how the 'execute' span will relate to the 'enqueue' span.
        #
        # propagation_option can be one of:
        # - :link (default) - the execution span will include a Link to the enqueue span.
        # - :child - the execution span will be the child of the enqueue span.
        # - :none - there will be neither a link, or a parent/child relationship between
        #           the enqueue and execution spans.
        #
        # Note that in all cases, the `messaging.message_id` attribute can be used to
        # manually correlate enqueue and execution spans.
        #
        # Example:
        # { "JobOne" => :link, "JobTwo" => :child, "JobThree" => :none }
        #
        option :context_propagation, default: {}, validate: -> (cfg) do
          return false unless cfg.is_a? Hash
          return false unless cfg.keys.all? { |k| k.is_a? String }

          return cfg.values.all? { |v| [:link, :child, :none].include?(v) }
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

        def validate_context_propagation(options)
        end
      end
    end
  end
end
