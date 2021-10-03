# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-api'

module OpenTelemetry
  module Instrumentation
    module RSpec
      # An RSpec Formatter that outputs Otel spans
      class Formatter
        attr_reader :output
        ::RSpec::Core::Formatters.register self, :example_started, :example_finished, :example_group_started, :example_group_finished, :start, :stop

        def initialize(output, tracer_provider: OpenTelemetry.tracer_provider)
          @tracer_provider = tracer_provider
          @spans_and_tokens = []
          @output = ''
        end

        def tracer
          @tracer ||= @tracer_provider.tracer('rspec')
        end

        def start(notification)
          span = tracer.start_span('suite')
          token = OpenTelemetry::Context.attach(
            OpenTelemetry::Trace.context_with_span(span)
          )
          @spans_and_tokens.unshift([span, token])
        end

        def stop(notification)
          span, token = *@spans_and_tokens.shift
          return unless span.recording?

          span.finish
          OpenTelemetry::Context.detach(token)
        end

        def example_group_started(notification)
          span = tracer.start_span(notification.group.description)
          token = OpenTelemetry::Context.attach(
            OpenTelemetry::Trace.context_with_span(span)
          )
          @spans_and_tokens.unshift([span, token])
        end

        def example_group_finished(notification)
          span, token = *@spans_and_tokens.shift
          return unless span.recording?

          span.finish
          OpenTelemetry::Context.detach(token)
        end

        def example_started(notification)
          example = notification.example
          attributes = {
            'location' => example.location.to_s,
            'full_description' => example.full_description.to_s,
            'described_class' => example.metadata[:described_class].to_s
          }
          span = tracer.start_span(example.description, attributes: attributes)
          token = OpenTelemetry::Context.attach(
            OpenTelemetry::Trace.context_with_span(span)
          )
          @spans_and_tokens.unshift([span, token])
        end

        def example_finished(notification)
          span, token = *@spans_and_tokens.shift
          return unless span.recording?

          span.finish
          OpenTelemetry::Context.detach(token)
        end
      end
    end
  end
end
