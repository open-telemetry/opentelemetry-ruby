# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'extensions/tracer_extension'

module OpenTelemetry
  module Adapters
    module Sinatra
      class Adapter < OpenTelemetry::Adapter
        def install
          register_tracer_extension
        end

        private

        def register_tracer_extension
          ::Sinatra::Base.send(:register, Extensions::TracerExtension)
        end
      end
    end
  end
end
