# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'pp'

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # Outputs {SpanData} to the console.
        #
        # Potentially useful for exploratory purposes.
        class ConsoleSpanExporter
          ResultCodes = OpenTelemetry::SDK::Trace::Export

          private_constant(:ResultCodes)

          def initialize
            @stopped = false
          end

          def export(spans)
            return ResultCodes::FAILURE if @stopped

            Array(spans).each { |s| pp s }

            ResultCodes::SUCCESS
          end

          def shutdown
            @stopped = true
          end
        end
      end
    end
  end
end
