# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      module Export
        # A LogExporter implementation that can be used to test OpenTelemetry integration.
        #
        # Example usage in a test suite:
        #
        # class MyClassTest
        #   def setup
        #     @log_emitter_provider = LogEmitterProvider.new
        #     # The default is `recording: true`, which is appropriate in non-test environments.
        #     @exporter = InMemoryLogExporter.new(recording: false)
        #     @log_emitter_provider.add_log_processor(SimpleLogProcessor.new(@exporter))
        #   end
        #
        #   def test_finished_logs
        #     @exporter.recording = true
        #     @log_emitter_provider.log_emitter.emit(LogRecord.new(body: "test"))
        #
        #     logs = @exporter.emitted_logs
        #     logs.wont_be_nil
        #     logs.size.must_equal(1)
        #     logs[0].body.must_equal("test")
        #
        #     @exporter.recording = false
        #   end
        class InMemoryLogExporter
          # Controls whether or not the exporter will export logs, or discard them.
          # @return [Boolean] when true, the exporter is recording. By default, this is true.
          attr_accessor :recording

          # Returns a new instance of the {InMemoryLogExporter}.
          #
          # @return a new instance of the {InMemoryLogExporter}.
          def initialize(recording: true)
            @emitted_logs = []
            @stopped = false
            @recording = recording
            @mutex = Mutex.new
          end

          # Returns a frozen array of the emitted {LogData}s
          #
          # @return [Array<LogData>] a frozen array of the emitted {LogData}s.
          def emitted_logs
            @mutex.synchronize do
              @emitted_logs.clone.freeze
            end
          end

          # Clears the internal collection of emitted {LogData}s.
          #
          # Does not reset the state of this exporter if already shutdown.
          def reset
            @mutex.synchronize do
              @emitted_logs.clear
            end
          end

          # Called to export emitted {LogData}s.
          #
          # @param [Enumerable<LogData>] log_datas the list of sampled {LogData}s to be
          #   exported.
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] the result of the export, SUCCESS or
          #   FAILURE
          def export(log_datas, timeout: nil)
            @mutex.synchronize do
              return FAILURE if @stopped

              @emitted_logs.concat(log_datas.to_a) if @recording
            end
            SUCCESS
          end

          # Called when {LogEmitterProvider#force_flush} is called, if this exporter is
          # registered to a {LogEmitterProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil)
            SUCCESS
          end

          # Called when {LogEmitterProvider#shutdown} is called, if this exporter is
          # registered to a {LogEmitterProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown(timeout: nil)
            @mutex.synchronize do
              @emitted_logs.clear
              @stopped = true
            end
            SUCCESS
          end
        end
      end
    end
  end
end
