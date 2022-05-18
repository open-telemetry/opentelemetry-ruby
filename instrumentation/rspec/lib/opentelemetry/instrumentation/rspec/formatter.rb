# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-api'
require_relative './version'

module OpenTelemetry
  module Instrumentation
    module RSpec
      # An RSpec Formatter that outputs Otel spans
      class Formatter
        attr_reader :output

        ::RSpec::Core::Formatters.register self, :example_started, :example_finished, :example_group_started, :example_group_finished, :start, :stop

        @clock = Time.method(:now)

        def self.current_timestamp
          @clock.call
        end

        def initialize(output = StringIO.new, tracer_provider = OpenTelemetry.tracer_provider)
          @spans_and_tokens = []
          @output = output
          @tracer_provider = tracer_provider
        end

        def tracer
          @tracer ||= @tracer_provider.tracer('OpenTelemetry::Instrumentation::RSpec', OpenTelemetry::Instrumentation::RSpec::VERSION)
        end

        def current_timestamp
          self.class.current_timestamp
        end

        def start(notification)
          span = tracer.start_span('RSpec suite', start_timestamp: current_timestamp)
          track_span(span)
        end

        def stop(notification)
          pop_and_finalize_span
        end

        def example_group_started(notification)
          description = notification.group.description
          span = tracer.start_span(description, start_timestamp: current_timestamp)
          track_span(span)
        end

        def example_group_finished(notification)
          pop_and_finalize_span
        end

        def example_started(notification)
          example = notification.example
          attributes = {
            'rspec.example.location' => example.location.to_s,
            'rspec.example.full_description' => example.full_description.to_s,
            'rspec.example.described_class' => example.metadata[:described_class].to_s
          }
          span = tracer.start_span(example.description, attributes: attributes, start_timestamp: current_timestamp)
          track_span(span)
        end

        def example_finished(notification)
          pop_and_finalize_span do |span|
            result = notification.example.execution_result

            span.set_attribute('rspec.example.result', result.status.to_s)

            add_exception_and_failures(span, result.exception)
          end
        end

        def add_exception_and_failures(span, exception)
          return if exception.nil?

          exception_message = strip_console_codes(exception.message)
          span.status = OpenTelemetry::Trace::Status.error(exception_message)

          span.set_attribute('rspec.example.failure_message', exception_message) if exception.is_a? ::RSpec::Expectations::ExpectationNotMetError

          if exception.is_a? ::RSpec::Core::MultipleExceptionError
            exception.all_exceptions.each do |error|
              record_stripped_exception(span, error)
            end
            span.set_attribute('rspec.example.failure_message', multiple_failure_message(exception)) if exception.failures.any?
          else
            span.record_exception(exception, attributes: { 'exception.message' => exception_message })
          end
        end

        def track_span(span)
          token = OpenTelemetry::Context.attach(
            OpenTelemetry::Trace.context_with_span(span)
          )
          @spans_and_tokens.unshift([span, token])
        end

        def pop_and_finalize_span
          span, token = *@spans_and_tokens.shift
          return unless span.recording?

          yield span if block_given?

          span.finish(end_timestamp: current_timestamp)
          OpenTelemetry::Context.detach(token)
        end

        def record_stripped_exception(span, error)
          error_message = strip_console_codes(error.message)
          span.record_exception(error, attributes: { 'exception.message' => error_message })
        end

        def strip_console_codes(string)
          string.gsub(/\e\[([;\d]+)?m/, '')
        end

        def multiple_failure_message(exception)
          exception.failures.map(&:message).map(&method(:strip_console_codes)).join("\n\n")
        end
      end
    end
  end
end
