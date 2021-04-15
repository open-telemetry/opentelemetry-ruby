# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Koala
      module Patches
        # Module to prepend to Koala::Facebook::API for instrumentation
        module Instrumentation
          VERBS_TO_SPAN_NAMES = Hash.new { |h, k| h[k] = "Koala #{k}" }

          def graph_call(path, args = {}, verb = 'get', options = {}, &post_processing)
            tracer.in_span(
              VERBS_TO_SPAN_NAMES[req.method],
              {
                'koala.verb' => verb,
                'koala.path' => path
              },
              kind: :client
            ) do |span|
              super(path, args, verb, options, &post_processing)
            end
          end

          private

          def tracer
            Koala.instance.tracer
          end
        end
      end
    end
  end
end
