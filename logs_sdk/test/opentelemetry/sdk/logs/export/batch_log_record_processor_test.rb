# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# rubocop:disable Lint/ConstantDefinitionInBlock, Style/Documentation
describe OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor do
  BatchLogRecordProcessor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor
  SUCCESS = OpenTelemetry::SDK::Logs::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Logs::Export::FAILURE
  TIMEOUT = OpenTelemetry::SDK::Logs::Export::TIMEOUT

  class TestExporter
    def initialize(status_codes: nil)
      @status_codes = status_codes || []
      @batches = []
      @failed_batches = []
    end

    attr_reader :batches, :failed_batches

    def export(batch, timeout: nil)
      # If status codes are empty, return success for less verbose testing
      s = @status_codes.shift
      if s.nil? || s == SUCCESS
        @batches << batch
        SUCCESS
      else
        @failed_batches << batch
        s
      end
    end

    def shutdown(timeout: nil); end

    def force_flush(timeout: nil); end
  end

  class NotAnExporter
  end

  class RaisingExporter
    def export(batch, timeout: nil)
      raise 'boom!'
    end

    def shutdown(timeout: nil); end

    def force_flush(timeout: nil); end
  end

  class TestLogRecord
    def initialize(body = nil)
      @body = body
    end

    attr_reader :body

    def to_log_record_data
      self
    end
  end

  let(:mock_context) { Minitest::Mock.new }

  describe 'initialization' do
    it 'raises if max batch size is greater than max queue size' do
      assert_raises ArgumentError do
        BatchLogRecordProcessor.new(TestExporter.new, max_queue_size: 6, max_export_batch_size: 999)
      end
    end

    it 'raises if OTEL_BLRP_EXPORT_TIMEOUT env var is not numeric' do
      assert_raises ArgumentError do
        OpenTelemetry::TestHelpers.with_env('OTEL_BLRP_EXPORT_TIMEOUT' => 'foo') do
          BatchLogRecordProcessor.new(TestExporter.new)
        end
      end
    end

    it 'raises if exporter is nil' do
      _(-> { BatchLogRecordProcessor.new(nil) }).must_raise(ArgumentError)
    end

    it 'raises if exporter is not an exporter' do
      _(-> { BatchLogRecordProcessor.new(NotAnExporter.new) }).must_raise(ArgumentError)
    end

    it 'sets parameters from the environment' do
      processor = OpenTelemetry::TestHelpers.with_env('OTEL_BLRP_EXPORT_TIMEOUT' => '4',
                                                      'OTEL_BLRP_SCHEDULE_DELAY' => '3',
                                                      'OTEL_BLRP_MAX_QUEUE_SIZE' => '2',
                                                      'OTEL_BLRP_MAX_EXPORT_BATCH_SIZE' => '1') do
        BatchLogRecordProcessor.new(TestExporter.new)
      end
      _(processor.instance_variable_get(:@exporter_timeout_seconds)).must_equal 0.004
      _(processor.instance_variable_get(:@delay_seconds)).must_equal 0.003
      _(processor.instance_variable_get(:@max_queue_size)).must_equal 2
      _(processor.instance_variable_get(:@batch_size)).must_equal 1
    end

    it 'prefers explicit parameters rather than the environment' do
      processor = OpenTelemetry::TestHelpers.with_env('OTEL_BLRP_EXPORT_TIMEOUT' => '4',
                                                      'OTEL_BLRP_SCHEDULE_DELAY' => '3',
                                                      'OTEL_BLRP_MAX_QUEUE_SIZE' => '2',
                                                      'OTEL_BLRP_MAX_EXPORT_BATCH_SIZE' => '1') do
        BatchLogRecordProcessor.new(TestExporter.new,
                                    exporter_timeout: 10,
                                    schedule_delay: 9,
                                    max_queue_size: 8,
                                    max_export_batch_size: 7)
      end
      _(processor.instance_variable_get(:@exporter_timeout_seconds)).must_equal 0.01
      _(processor.instance_variable_get(:@delay_seconds)).must_equal 0.009
      _(processor.instance_variable_get(:@max_queue_size)).must_equal 8
      _(processor.instance_variable_get(:@batch_size)).must_equal 7
    end

    it 'sets defaults for parameters not in the environment' do
      processor = BatchLogRecordProcessor.new(TestExporter.new)
      _(processor.instance_variable_get(:@exporter_timeout_seconds)).must_equal 30.0
      _(processor.instance_variable_get(:@delay_seconds)).must_equal 1.0
      _(processor.instance_variable_get(:@max_queue_size)).must_equal 2048
      _(processor.instance_variable_get(:@batch_size)).must_equal 512
    end

    it 'spawns a thread on boot by default' do
      mock = Minitest::Mock.new
      mock.expect(:call, nil)

      Thread.stub(:new, mock) do
        BatchLogRecordProcessor.new(TestExporter.new)
      end

      mock.verify
    end

    it 'spawns a thread on boot if OTEL_RUBY_BLRP_START_THREAD_ON_BOOT is true' do
      mock = Minitest::Mock.new
      mock.expect(:call, nil)

      Thread.stub(:new, mock) do
        OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_BLRP_START_THREAD_ON_BOOT' => 'true') do
          BatchLogRecordProcessor.new(TestExporter.new)
        end
      end

      mock.verify
    end

    it 'does not spawn a thread on boot if OTEL_RUBY_BLRP_START_THREAD_ON_BOOT is false' do
      mock = Minitest::Mock.new
      mock.expect(:call, nil) { assert false }

      Thread.stub(:new, mock) do
        OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_BLRP_START_THREAD_ON_BOOT' => 'false') do
          BatchLogRecordProcessor.new(TestExporter.new)
        end
      end
    end

    it 'prefers explicit start_thread_on_boot parameter rather than the environment' do
      mock = Minitest::Mock.new
      mock.expect(:call, nil) { assert false }

      Thread.stub(:new, mock) do
        OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_BLRP_START_THREAD_ON_BOOT' => 'true') do
          BatchLogRecordProcessor.new(TestExporter.new,
                                      start_thread_on_boot: false)
        end
      end
    end
  end

  describe '#on_emit' do
    it 'adds the log record to the batch' do
      processor = BatchLogRecordProcessor.new(TestExporter.new)
      log_record = TestLogRecord.new

      processor.on_emit(log_record, mock_context)

      assert_includes(processor.instance_variable_get(:@log_records), log_record)
    end

    it 'removes the older log records from the batch if full' do
      skip 'intermittent failure, see: #1701'

      processor = BatchLogRecordProcessor.new(TestExporter.new, max_queue_size: 1, max_export_batch_size: 1)

      # Don't actually try to export, we're looking at the log records array
      processor.stub(:work, nil) do
        older_log_record = TestLogRecord.new
        newest_log_record = TestLogRecord.new

        processor.on_emit(older_log_record, mock_context)
        processor.on_emit(newest_log_record, mock_context)

        records = processor.instance_variable_get(:@log_records)

        assert_includes(records, newest_log_record)
        refute_includes(records, older_log_record)
      end
    end

    it 'logs a warning if a log record was emitted after the buffer is full' do
      # This will be fixed as part of Issue #1701
      # https://github.com/open-telemetry/opentelemetry-ruby/issues/1701
      skip if RUBY_ENGINE == 'jruby'

      mock_otel_logger = Minitest::Mock.new
      mock_otel_logger.expect(:warn, nil, ['1 log record(s) dropped. Reason: buffer-full'])

      OpenTelemetry.stub(:logger, mock_otel_logger) do
        processor = BatchLogRecordProcessor.new(TestExporter.new, max_queue_size: 1, max_export_batch_size: 1)

        log_record = TestLogRecord.new
        log_record2 = TestLogRecord.new

        processor.on_emit(log_record, mock_context)
        processor.on_emit(log_record2, mock_context)
      end

      mock_otel_logger.verify
    end

    it 'does not emit a log record if stopped' do
      processor = BatchLogRecordProcessor.new(TestExporter.new)

      processor.instance_variable_set(:@stopped, true)
      processor.on_emit(TestLogRecord.new, mock_context)

      assert_empty(processor.instance_variable_get(:@log_records))
    end
  end

  describe '#force_flush' do
    it 'reenqueues excess log_records on timeout' do
      exporter = TestExporter.new
      processor = BatchLogRecordProcessor.new(exporter)

      processor.on_emit(TestLogRecord.new, mock_context)
      result = processor.force_flush(timeout: 0)

      _(result).must_equal(TIMEOUT)

      _(exporter.failed_batches.size).must_equal(0)
      _(exporter.batches.size).must_equal(0)

      _(processor.instance_variable_get(:@log_records).size).must_equal(1)
    end

    it 'exports the log record data and calls #force_flush on the exporter' do
      mock_exporter = Minitest::Mock.new
      processor = BatchLogRecordProcessor.new(TestExporter.new)
      processor.instance_variable_set(:@exporter, mock_exporter)
      log_record = TestLogRecord.new
      log_record_data_mock = Minitest::Mock.new

      log_record.stub(:to_log_record_data, log_record_data_mock) do
        processor.on_emit(log_record, mock_context)
        mock_exporter.expect(:export, 0, [[log_record_data_mock]], timeout: nil)
        mock_exporter.expect(:force_flush, nil, timeout: nil)
        processor.force_flush
        mock_exporter.verify
      end
    end

    it 'returns failure code if export_batch fails' do
      processor = BatchLogRecordProcessor.new(TestExporter.new)

      processor.stub(:export_batch, OpenTelemetry::SDK::Logs::Export::FAILURE) do
        processor.on_emit(TestLogRecord.new, mock_context)
        assert_equal(OpenTelemetry::SDK::Logs::Export::FAILURE, processor.force_flush)
      end
    end

    it 'reports dropped logs if timeout occurs with full buffer' do
      mock_otel_logger = Minitest::Mock.new
      mock_otel_logger.expect(:warn, nil, [/buffer-full/])

      OpenTelemetry.stub(:logger, mock_otel_logger) do
        OpenTelemetry::Common::Utilities.stub(:maybe_timeout, 0) do
          processor = BatchLogRecordProcessor.new(TestExporter.new, max_queue_size: 1, max_export_batch_size: 1)
          processor.instance_variable_set(:@log_records, [TestLogRecord.new, TestLogRecord.new, TestLogRecord.new])
          processor.force_flush
        end
      end

      mock_otel_logger.verify
    end
  end

  describe '#shutdown' do
    it 'does not allow subsequent calls to emit after shutdown' do
      processor = BatchLogRecordProcessor.new(TestExporter.new)

      processor.shutdown
      processor.on_emit(TestLogRecord.new, mock_context)

      assert_empty(processor.instance_variable_get(:@log_records))
    end

    it 'does not send shutdown to exporter if already shutdown' do
      exporter = TestExporter.new
      processor = BatchLogRecordProcessor.new(exporter)

      processor.instance_variable_set(:@stopped, true)

      exporter.stub(:shutdown, ->(_) { raise 'whoops!' }) do
        processor.shutdown
      end
    end

    it 'sets @stopped to true' do
      processor = BatchLogRecordProcessor.new(TestExporter.new)

      refute(processor.instance_variable_get(:@stopped))

      processor.shutdown

      assert(processor.instance_variable_get(:@stopped))
    end

    it 'respects the timeout' do
      exporter = TestExporter.new
      processor = BatchLogRecordProcessor.new(exporter)

      processor.on_emit(TestLogRecord.new, mock_context)
      processor.shutdown(timeout: 0)

      _(exporter.failed_batches.size).must_equal(0)
      _(exporter.batches.size).must_equal(0)

      _(processor.instance_variable_get(:@log_records).size).must_equal(1)
    end

    it 'works if the thread is not running' do
      processor = BatchLogRecordProcessor.new(TestExporter.new, start_thread_on_boot: false)
      processor.shutdown(timeout: 0)
    end

    it 'returns a SUCCESS status if no error' do
      test_exporter = TestExporter.new
      test_exporter.instance_eval do
        def shutdown(timeout: nil)
          SUCCESS
        end
      end

      processor = BatchLogRecordProcessor.new(test_exporter)
      processor.on_emit(TestLogRecord.new, mock_context)
      result = processor.shutdown(timeout: 0)

      _(result).must_equal(SUCCESS)
    end

    it 'returns a FAILURE status if a non-specific export error occurs' do
      test_exporter = TestExporter.new
      test_exporter.instance_eval do
        def shutdown(timeout: nil)
          FAILURE
        end
      end

      processor = BatchLogRecordProcessor.new(test_exporter)
      processor.on_emit(TestLogRecord.new, mock_context)
      result = processor.shutdown(timeout: 0)

      _(result).must_equal(FAILURE)
    end

    it 'returns a TIMEOUT status if a timeout export error occurs' do
      test_exporter = TestExporter.new
      test_exporter.instance_eval do
        def shutdown(timeout: nil)
          TIMEOUT
        end
      end

      processor = BatchLogRecordProcessor.new(test_exporter)
      processor.on_emit(TestLogRecord.new, mock_context)
      result = processor.shutdown(timeout: 0)

      _(result).must_equal(TIMEOUT)
    end
  end

  describe 'lifecycle' do
    it 'should stop and start correctly' do
      processor = BatchLogRecordProcessor.new(TestExporter.new)
      processor.shutdown
    end

    it 'should flush everything on shutdown' do
      exporter = TestExporter.new
      processor = BatchLogRecordProcessor.new(exporter)
      log_record = TestLogRecord.new

      processor.on_emit(log_record, mock_context)
      processor.shutdown

      _(exporter.batches).must_equal [[log_record]]
    end
  end

  describe 'batching' do
    it 'should batch up to but not over the max_batch' do
      exporter = TestExporter.new
      processor = BatchLogRecordProcessor.new(exporter, max_queue_size: 6, max_export_batch_size: 3)

      log_records = [TestLogRecord.new, TestLogRecord.new, TestLogRecord.new, TestLogRecord.new]
      log_records.each { |log_record| processor.on_emit(log_record, mock_context) }
      processor.shutdown

      _(exporter.batches[0].size).must_equal(3)
    end
  end

  describe 'export retry' do
    it 'should not retry on FAILURE exports' do
      exporter = TestExporter.new(status_codes: [FAILURE, SUCCESS])
      processor = BatchLogRecordProcessor.new(exporter,
                                              schedule_delay: 999,
                                              max_queue_size: 6,
                                              max_export_batch_size: 3)
      log_records = [TestLogRecord.new, TestLogRecord.new, TestLogRecord.new, TestLogRecord.new]
      log_records.each { |log_record| processor.on_emit(log_record, mock_context) }

      # Ensure that our work thread has time to loop
      sleep(1)
      processor.shutdown

      _(exporter.batches.size).must_equal(1)
      _(exporter.batches[0].size).must_equal(1)

      _(exporter.failed_batches.size).must_equal(1)
      _(exporter.failed_batches[0].size).must_equal(3)
    end
  end

  describe 'stress test' do
    it 'does not blow up with a lot of things' do
      exporter = TestExporter.new
      processor = BatchLogRecordProcessor.new(exporter)

      producers = 10.times.map do |i|
        Thread.new do
          x = i * 10
          10.times do |j|
            processor.on_emit(TestLogRecord.new(x + j), mock_context)
          end
          sleep(rand(0.01))
        end
      end
      producers.each(&:join)
      processor.shutdown

      out = exporter.batches.flatten.map(&:body).sort

      expected = 100.times.map { |i| i }

      _(out).must_equal(expected)
    end
  end

  describe 'faulty exporter' do
    let(:exporter) { RaisingExporter.new }
    let(:processor) { BatchLogRecordProcessor.new(exporter) }

    it 'reports export failures' do
      # skip the work method's behavior, we rely on shutdown to get us to the failures
      processor.stub(:work, nil) do
        mock_logger = Minitest::Mock.new
        mock_logger.expect(:error, nil, [/Unable to export/])
        mock_logger.expect(:error, nil, [/Result code: 1/])
        mock_logger.expect(:error, nil, [/unexpected error in .*\#export_batch/])

        OpenTelemetry.stub(:logger, mock_logger) do
          log_records = [TestLogRecord.new, TestLogRecord.new, TestLogRecord.new, TestLogRecord.new]
          log_records.each { |log_record| processor.on_emit(log_record, mock_context) }
          processor.shutdown
        end

        mock_logger.verify
      end
    end
  end

  describe 'fork safety test' do
    let(:exporter) { TestExporter.new }
    let(:processor) do
      BatchLogRecordProcessor.new(exporter,
                                  max_queue_size: 10,
                                  max_export_batch_size: 3)
    end

    it 'when ThreadError is raised it handles it gracefully' do
      parent_pid = processor.instance_variable_get(:@pid)
      parent_work_thread_id = processor.instance_variable_get(:@thread).object_id
      Process.stub(:pid, parent_pid + rand(1..10)) do
        Thread.stub(:new, -> { raise ThreadError }) do
          processor.on_emit(TestLogRecord.new, mock_context)
        end

        current_pid = processor.instance_variable_get(:@pid)
        current_work_thread_id = processor.instance_variable_get(:@thread).object_id
        _(parent_pid).wont_equal current_pid
        _(parent_work_thread_id).must_equal current_work_thread_id
      end
    end

    describe 'when a process fork occurs' do
      it 'creates new work thread when emit is called' do
        parent_pid = processor.instance_variable_get(:@pid)
        parent_work_thread_id = processor.instance_variable_get(:@thread).object_id
        Process.stub(:pid, parent_pid + rand(1..10)) do
          # Emit a new log record on the forked process and export it.
          processor.on_emit(TestLogRecord.new, mock_context)
          current_pid = processor.instance_variable_get(:@pid)
          current_work_thread_id = processor.instance_variable_get(:@thread).object_id
          _(parent_pid).wont_equal current_pid
          _(parent_work_thread_id).wont_equal current_work_thread_id
        end
      end

      it 'creates new work thread when force_flush' do
        parent_pid = processor.instance_variable_get(:@pid)
        parent_work_thread_id = processor.instance_variable_get(:@thread).object_id
        Process.stub(:pid, parent_pid + rand(1..10)) do
          # Force flush on the forked process.
          processor.force_flush
          current_pid = processor.instance_variable_get(:@pid)
          current_work_thread_id = processor.instance_variable_get(:@thread).object_id
          _(parent_pid).wont_equal current_pid
          _(parent_work_thread_id).wont_equal current_work_thread_id
        end
      end
    end
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock, Style/Documentation
