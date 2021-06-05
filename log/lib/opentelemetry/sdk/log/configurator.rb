# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    class Configurator
      def configure_logging_sdk
        @log_processors = []
        configure_log_processors
        OpenTelemetry.log_emitter_provider = log_emitter_provider
      end

      # Add a log processor to the export pipeline
      #
      # @param [#on_emit, #shutdown, #force_flush] log_processor A log_processor
      #   that satisfies the duck type #on_emit, #shutdown, #force_flush. See
      #   {SimpleLogProcessor} for an example.
      def add_log_processor(log_processor)
        @log_processors << log_processor
      end

      private

      def log_emitter_provider
        @log_emitter_provider ||= Log::LogEmitterProvider.new(@resource)
      end

      def configure_log_processors
        processors = @log_processors.empty? ? [wrapped_log_exporter_from_env].compact : @log_processors
        processors.each { |p| log_emitter_provider.add_log_processor(p) }
      end

      def wrapped_log_exporter_from_env
        exporter = ENV.fetch('OTEL_LOGS_EXPORTER', 'console') # TODO: OTLP
        case exporter
        when 'none' then nil
        # when 'otlp' then fetch_exporter(exporter, 'OpenTelemetry::Exporter::OTLP::Exporter')
        when 'console' then Log::Export::SimpleLogProcessor.new(Log::Export::ConsoleLogExporter.new)
        else
          OpenTelemetry.logger.warn "The #{exporter} exporter is unknown and cannot be configured, spans will not be exported"
          nil
        end
      end
    end
  end
end
