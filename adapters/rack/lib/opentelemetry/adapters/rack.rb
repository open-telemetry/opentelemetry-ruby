# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Rack
      module_function

      def install(config = {})
        require_relative 'rack/adapter'
        Rack::Adapter.install(config)
      end

      # Convenience method to access the nested module name
      def name
        Module.nesting[0].to_s
      end

      # Convenience method to access the adapter version
      def version
        VERSION
      end
    end
  end
end

require_relative './rack/version'
