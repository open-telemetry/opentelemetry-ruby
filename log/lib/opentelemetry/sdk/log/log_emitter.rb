# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      # {LogEmitter} emits LogRecords to the registered
      # LogProcessors for eventual export via the LogExporters
      class LogEmitter
        attr_reader :name, :version, :log_emitter_provider

        # @api private
        #
        # Returns a new {LogEmitter} instance.
        #
        # @param [String] name Instrumentation package name
        # @param [String] version Instrumentation package version
        # @param [LogEmitterProvider] log_emitter_provider LogEmitterProvider that initialized the LogEmitter
        #
        # @return [LogEmitter]
        def initialize(name, version, log_emitter_provider)
          @name = name
          @version = version
          @instrumentation_library = InstrumentationLibrary.new(name, version)
          @log_emitter_provider = log_emitter_provider
        end

        # Emit a {LogRecord} for processing.
        #
        # @param [LogRecord] log_record The log record to be emitted. Callers are expected to have populated the log_record with relevant information from the {Context} if necessary.
        def emit(log_record)
          # TODO: if we move flush to this class, we'll also need
          # to probably move the stopped? check to an appropriate
          # place.
          if !log_emitter_provider.stopped?
            log_emitter_provider.active_log_processor.on_emit(
              LogData.new(
                log_record.timestamp,
                log_record.trace_id,
                log_record.span_id,
                log_record.trace_flags,
                log_record.severity_text,
                log_record.severity_number,
                log_record.name,
                log_record.body,
                log_record.attributes,
                log_emitter_provider.resource,
                @instrumentation_library
              )
            )
          end
        end

        # @todo the sdk otep specifies that #force should
        # be here, but the tracing sdks have it on the provider
        # classes (not the tracer/"emitter" classes)
        # def flush; end
      end
    end
  end
end
