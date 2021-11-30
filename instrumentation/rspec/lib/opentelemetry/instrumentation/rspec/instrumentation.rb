# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RSpec
      # The Instrumentation class contains logic to detect and install the Rspec instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          add_formatter!
        end

        present do
          defined?(::RSpec)
        end

        private

        def require_dependencies
          require_relative './formatter'
        end

        def add_formatter!
          ::RSpec.configure do |config|
            config.add_formatter(Formatter)
          end
        end
      end
    end
  end
end
