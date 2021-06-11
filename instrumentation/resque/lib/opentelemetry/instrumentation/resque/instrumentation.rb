# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Resque
      # The Instrumentation class contains logic to detect and install the Resque instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Resque)
        end

        option :span_naming,       default: :queue, validate: ->(opt) { %I[job_class queue].include?(opt) }
        option :propagation_style, default: :link,  validate: ->(opt) { %i[link child none].include?(opt) }

        private

        def patch
          ::Resque.prepend(Patches::ResqueModule)
          ::Resque::Job.prepend(Patches::ResqueJob)
        end

        def require_dependencies
          require_relative 'patches/resque_module'
          require_relative 'patches/resque_job'
        end
      end
    end
  end
end
