# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'extensions/tracer_extension'

module OpenTelemetry
  module Instrumentation
    module Sinatra
      # The Instrumentation class contains logic to detect and install the Sinatra
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_|
          ::Sinatra::Base.register Extensions::TracerExtension
        end

        present do
          defined?(::Sinatra)
        end
      end
    end
  end
end
