# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Dalli
      module Patches
        # Module to prepend to Dalli::Server for instrumentation
        module Server
          def request(op, *args)
            operation = Utils.opname(op, multi?)
            attributes = {
              'db.system' => 'memcached',
              'db.statement' => Utils.format_command(operation, args),
              'peer.hostname' => hostname,
              'peer.port' => port
            }

            tracer.in_span(operation, attributes: attributes, kind: :client) do
              super
            end
          end

          private

          def tracer
            Dalli::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
