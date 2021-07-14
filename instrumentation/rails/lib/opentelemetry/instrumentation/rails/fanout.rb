# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rails
      # This is a replacement for the default Fanout notifications queue, which adds special
      # handling around returned context from the SpanSubscriber notification handlers.
      # Used together, it allows us to trace arbitrary ActiveSupport::Notifications safely.
      class Fanout < ::ActiveSupport::Notifications::Fanout
        def start(name, id, payload)
          listeners_for(name).map do |s|
            result = [s]
            state = s.start(name, id, payload)
            if state.is_a?(Array) && state[0].is_a?(OpenTelemetry::Trace::Span) && state[1] # rubocop:disable Style/IfUnlessModifier
              result << state
            end

            result
          end
        end

        def finish(name, id, payload, listeners = listeners_for(name))
          listeners.each do |(s, arr)|
            span, token = arr
            if span.is_a?(OpenTelemetry::Trace::Span) && token
              s.finish(
                name,
                id,
                payload.merge(
                  __opentelemetry_span: span,
                  __opentelemetry_ctx_token: token
                )
              )
            else
              s.finish(name, id, payload)
            end
          end
        end

        def listeners_for(name)
          listeners = super
          listeners.sort_by do |l|
            l.instance_variable_get(:@delegate).is_a?(SpanSubscriber) ? -1 : 1
          end
        end
      end
    end
  end
end
