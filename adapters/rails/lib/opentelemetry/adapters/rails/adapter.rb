# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'middlewares'

module OpenTelemetry
  module Adapters
    module Rails
      # The Adapter class contains logic to detect and install the Sinatra
      # instrumentation adapter
      class Adapter < OpenTelemetry::Instrumentation::Adapter
        install do |_|
          ::ActiveSupport.on_load(:before_initialize) do
            self.middleware.insert_after(
              ActionDispatch::ShowExceptions,
              OpenTelemetry::Adapters::Rails::ExceptionMiddleware
            )
          end
        end

        present do
          defined?(::Rails)
        end
      end
    end
  end
end
