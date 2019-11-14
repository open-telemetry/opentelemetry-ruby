# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Faraday
      module_function

      TRACER_NAME = 'faraday'

      def install(config = {name: TRACER_NAME,
                            version: tracer_version})
        require_relative 'faraday/adapter'
        Faraday::Adapter.install(config)
      end

      def tracer_version
        Gem.loaded_specs[TRACER_NAME]&.version.to_s
      end
      private_class_method(:tracer_version)
    end
  end
end
