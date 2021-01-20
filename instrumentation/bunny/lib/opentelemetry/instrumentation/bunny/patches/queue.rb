# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Bunny
      module Patches
        # The Queue module contains the instrumentation patch the Queue#pop method.
        module Queue
          def pop(opts = { manual_ack: false }, &block)
            super do |delivery_info, properties, payload|
              if block
                OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_process_span(tracer, delivery_info, properties) do
                  yield delivery_info, properties, payload
                end
              else
                OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_receive_span(tracer, delivery_info, properties) do
                  [delivery_info, properties, payload]
                end
              end
            end
          end

          private

          def tracer
            Bunny::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
