# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/configurator'

module OpenTelemetry
  module SDK
    module Logs
      # The ConfiguratorPatch implements a hook to configure the logs portion
      # of the SDK.
      module ConfiguratorPatch
        def add_log_record_processor(log_record_processor)
          OpenTelemetry.logger.info("#add_log_record_processor called, provided: #{log_record_processor}.")
          @log_record_processors << log_record_processor
          OpenTelemetry.logger.info("@log_record_processors is now: #{@log_record_processors}")
        end

        private

        def initialize
          super
          @log_record_processors = []
        end

        # The logs_configuration_hook method is where we define the setup
        # process for logs SDK.
        def logs_configuration_hook
          OpenTelemetry.logger.info('#logs_configuration_hook called')
          OpenTelemetry.logger_provider = Logs::LoggerProvider.new(resource: @resource)
          OpenTelemetry.logger.info("logger_provider = #{@logger_provider}")
          configure_log_record_processors
        end

        def configure_log_record_processors
          processors = @log_record_processors.empty? ? wrapped_log_exporters_from_env.compact : @log_record_processors
          OpenTelemetry.logger.info("#configure_log_record_processors, processors = #{processors}")
          processors.each { |p| OpenTelemetry.logger_provider.add_log_record_processor(p) }
        end

        def wrapped_log_exporters_from_env
          # TODO: set default to OTLP to match traces, default is console until other exporters merged
          exporters = ENV.fetch('OTEL_LOGS_EXPORTER', 'console')
          OpenTelemetry.logger.info("#wrapped_log_exporters_from_env, exporters = #{exporters}")

          exporters.split(',').map do |exporter|
            case exporter.strip
            when 'none'
              OpenTelemetry.logger.info('none exporter reached')
              nil
            when 'console'
              OpenTelemetry.logger.info('console exporter reached')
              Logs::Export::SimpleLogRecordProcessor.new(Logs::Export::ConsoleLogRecordExporter.new)
            when 'in-memory'
              Logs::Export::SimpleLogRecordProcessor.new(Logs::Export::InMemoryLogRecordExporter.new)
            when 'otlp'
              OpenTelemetry.logger.info('otlp exporter reached')
              otlp_protocol = ENV['OTEL_EXPORTER_OTLP_LOGS_PROTOCOL'] || ENV['OTEL_EXPORTER_OTLP_PROTOCOL'] || 'http/protobuf'
              OpenTelemetry.logger.info("otlp_protocol = #{otlp_protocol}")
              if otlp_protocol != 'http/protobuf'
                OpenTelemetry.logger.warn "The #{otlp_protocol} transport protocol is not supported by the OTLP exporter, log_records will not be exported."
                nil
              else
                begin
                  processor = Logs::Export::BatchLogRecordProcessor.new(OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new)
                  OpenTelemetry.logger.info("processor = #{processor}")
                  processor
                rescue NameError
                  OpenTelemetry.logger.warn 'The otlp logs exporter cannot be configured - please add opentelemetry-exporter-otlp-logs to your Gemfile. Logs will not be exported'
                  nil
                rescue => e
                  OpenTelemetry.handle_error(exception: e, message: "Error in Logs::ConfigurationPatch#wrapped_log_exporters_from_env")
                end
              end
            else
              OpenTelemetry.logger.warn "The #{exporter} exporter is unknown and cannot be configured, log records will not be exported"
              nil
            end
          end
        end
      end
    end
  end
end

OpenTelemetry::SDK::Configurator.prepend(OpenTelemetry::SDK::Logs::ConfiguratorPatch)
