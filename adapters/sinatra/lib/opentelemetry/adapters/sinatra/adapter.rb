# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'sinatra'

require_relative 'extensions/tracer_extension'

module OpenTelemetry
  module Adapters
    module Sinatra
      class Adapter < OpenTelemetry::Instrumentation::Adapter
        install do |_|
          ::Sinatra::Base.register Extensions::TracerExtension
        end

        present do
          Gem.loaded_specs.include?("sinatra")
        end
      end
    end
  end
end
