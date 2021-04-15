# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Koala
      module Patches
        # Module to prepend to Koala::Facebook::API for instrumentation
        module Api
          VERBS_TO_SPAN_NAMES = Hash.new { |h, k| h[k] = "Koala #{k}" }

          def graph_call(path, args = {}, verb = 'get', options = {}, &post_processing)
            tracer.in_span(
              VERBS_TO_SPAN_NAMES[verb],
              attributes: {
                'koala.verb' => verb,
                'koala.path' => path
              },
              kind: :client
            ) do |_|
              OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'facebook') do
                super
              end
            end
          end

          private

          def tracer
            Koala::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
