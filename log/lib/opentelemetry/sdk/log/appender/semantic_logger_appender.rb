# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'semantic_logger'

module OpenTelemetry
  module SDK
    module Log
      module Appender
        class SemanticLoggerAppender < SemanticLogger::Subscriber
          def initialize(log_emitter:, **args, &block)
            @log_emitter = log_emitter
            super(**args, &block)
          end

          def log(log)
            @log_emitter.emit(
              Log::LogRecord.new(attributes_from_log_struct(log))
            )
          end

          def flush
            @log_emitter.log_emitter_provider.force_flush
          end

          def close
            @log_emitter.log_emitter_provider.shutdown
          end

          def attributes_from_log_struct(log)
            attributes = {
              # TODO: I don't think this is the right precision
              timestamp: log.time.to_i,
              severity_text: log.level.to_s,
              severity_number: severity_number_from_level(log.level),
              name: log.name,
              body: log.message
            }

            if log.payload.is_a? Hash
              attributes[:attributes] = log.payload
            end

            if log.context[:opentelemetry_span]&.context.valid?
              attributes[:trace_id] = log.context[:opentelemetry_span].context.hex_trace_id
              attributes[:span_id] = log.context[:opentelemetry_span].context.hex_span_id
              attributes[:trace_flags] = log.context[:opentelemetry_span].context.trace_flags
            end

            attributes
          end

          def severity_number_from_level(level)
            # TODO: make this a constant somewhere
            case level
            when :trace
              1 
            when :debug
              5
            when :info
              9
            when :warn
              13
            when :error
              17
            when :fatal
              21
            else
              9
            end
          end
        end
      end
    end
  end
end
