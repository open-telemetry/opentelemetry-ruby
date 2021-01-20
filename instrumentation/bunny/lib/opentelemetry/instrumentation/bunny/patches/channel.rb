# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Bunny
      module Patches
        # The Channel module contains the instrumentation patch the Channel#basic_publish method
        module Channel
          def basic_publish(payload, exchange, routing_key, opts = {})
            OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_send_span(tracer, exchange, routing_key) do
              opts[:headers] ||= {}
              OpenTelemetry.propagation.text.inject(opts[:headers])
              super(payload, exchange, routing_key, opts)
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
