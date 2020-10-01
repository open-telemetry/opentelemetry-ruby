# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
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
        end

        present do
          defined?(::Rails)
        end

        private

        def require_dependencies
          require_relative 'middlewares/tracer_middleware'
        end

        def require_railtie
          require_relative 'railtie'
        end
      end
    end
  end
end
