# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor do
  BatchSpanProcessor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE

  class TestExporter
    def initialize(status_codes: nil)
      @status_codes = status_codes || []
      @batches = []
      @failed_batches = []
    end

    attr_reader :batches
    attr_reader :failed_batches

    def export(batch)
      # If status codes is empty, its a success for less verbose testing
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
  end

  class TestTimeoutExporter < TestExporter
    attr_reader :state

    def initialize(sleep_for_millis: 0, **args)
      @sleep_for_seconds = sleep_for_millis / 1000.0
      super(**args)
    end

    def export(batch)
      @state = :called
      # long enough to cause a timeout:
      sleep @sleep_for_seconds
      @state = :not_interrupted
      super
    end
  end

  class TestSpan
    def initialize(id = nil, recording = true)
      trace_flags = recording ? OpenTelemetry::Trace::TraceFlags::SAMPLED : OpenTelemetry::Trace::TraceFlags::DEFAULT
      @context = OpenTelemetry::Trace::SpanContext.new(trace_flags: trace_flags)
      @id = id
      @recording = recording
    end

    attr_reader :id, :context

    def recording?
      @recording
    end

    def to_span_data
      self
    end
  end

  describe 'initialization' do
    it 'if max batch size is gt max queue size raise' do
      assert_raises ArgumentError do
        BatchSpanProcessor.new(exporter: TestExporter.new, max_queue_size: 6, max_export_batch_size: 999)
      end
    end

    it 'raises if OTEL_BSP_EXPORT_TIMEOUT_MILLIS env var is not numeric' do
      assert_raises ArgumentError do
        with_env('OTEL_BSP_EXPORT_TIMEOUT_MILLIS' => 'foo') do
          BatchSpanProcessor.new(exporter: TestExporter.new)
        end
      end
    end

    it 'sets parameters from the environment' do
      bsp = with_env('OTEL_BSP_EXPORT_TIMEOUT_MILLIS' => '4',
                     'OTEL_BSP_SCHEDULE_DELAY_MILLIS' => '3',
                     'OTEL_BSP_MAX_QUEUE_SIZE' => '2',
                     'OTEL_BSP_MAX_EXPORT_BATCH_SIZE' => '1') do
        BatchSpanProcessor.new(exporter: TestExporter.new)
      end
      _(bsp.instance_variable_get(:@exporter_timeout_seconds)).must_equal 0.004
      _(bsp.instance_variable_get(:@delay_seconds)).must_equal 0.003
      _(bsp.instance_variable_get(:@max_queue_size)).must_equal 2
      _(bsp.instance_variable_get(:@batch_size)).must_equal 1
    end

    it 'prefers explicit parameters rather than the environment' do
      bsp = with_env('OTEL_BSP_EXPORT_TIMEOUT_MILLIS' => '4',
                     'OTEL_BSP_SCHEDULE_DELAY_MILLIS' => '3',
                     'OTEL_BSP_MAX_QUEUE_SIZE' => '2',
                     'OTEL_BSP_MAX_EXPORT_BATCH_SIZE' => '1') do
        BatchSpanProcessor.new(exporter: TestExporter.new,
                               exporter_timeout_millis: 10,
                               schedule_delay_millis: 9,
                               max_queue_size: 8,
                               max_export_batch_size: 7)
      end
      _(bsp.instance_variable_get(:@exporter_timeout_seconds)).must_equal 0.01
      _(bsp.instance_variable_get(:@delay_seconds)).must_equal 0.009
      _(bsp.instance_variable_get(:@max_queue_size)).must_equal 8
      _(bsp.instance_variable_get(:@batch_size)).must_equal 7
    end

    it 'sets defaults for parameters not in the environment' do
      bsp = BatchSpanProcessor.new(exporter: TestExporter.new)
      _(bsp.instance_variable_get(:@exporter_timeout_seconds)).must_equal 30.0
      _(bsp.instance_variable_get(:@delay_seconds)).must_equal 5.0
      _(bsp.instance_variable_get(:@max_queue_size)).must_equal 2048
      _(bsp.instance_variable_get(:@batch_size)).must_equal 512
    end

    it 'spawns a thread on boot by default' do
      mock = MiniTest::Mock.new
      mock.expect(:call, nil)

      Thread.stub(:new, mock) do
        BatchSpanProcessor.new(exporter: TestExporter.new)
      end

      mock.verify
    end

    it 'spawns a thread on boot if OTEL_RUBY_BSP_START_THREAD_ON_BOOT is true' do
      mock = MiniTest::Mock.new
      mock.expect(:call, nil)

      Thread.stub(:new, mock) do
        with_env('OTEL_RUBY_BSP_START_THREAD_ON_BOOT' => 'true') do
          BatchSpanProcessor.new(exporter: TestExporter.new)
        end
      end

      mock.verify
    end

    it 'does not spawn a thread on boot if OTEL_RUBY_BSP_START_THREAD_ON_BOOT is false' do
      mock = MiniTest::Mock.new
      mock.expect(:call, nil) { assert false }

      Thread.stub(:new, mock) do
        with_env('OTEL_RUBY_BSP_START_THREAD_ON_BOOT' => 'false') do
          BatchSpanProcessor.new(exporter: TestExporter.new)
        end
      end
    end

    it 'prefers explicit start_thread_on_boot parameter rather than the environment' do
      mock = MiniTest::Mock.new
      mock.expect(:call, nil) { assert false }

      Thread.stub(:new, mock) do
        with_env('OTEL_RUBY_BSP_START_THREAD_ON_BOOT' => 'true') do
          BatchSpanProcessor.new(exporter: TestExporter.new,
                                 start_thread_on_boot: false)
        end
      end
    end
  end

  describe 'lifecycle' do
    it 'should stop and start correctly' do
      bsp = BatchSpanProcessor.new(exporter: TestExporter.new)
      bsp.shutdown
    end

    it 'should flush everything on shutdown' do
      te = TestExporter.new
      bsp = BatchSpanProcessor.new(exporter: te)
      ts = TestSpan.new
      bsp.on_finish(ts)

      bsp.shutdown

      _(te.batches).must_equal [[ts]]
    end
  end

  describe 'batching' do
    it 'should batch up to but not over the max_batch' do
      te = TestExporter.new

      bsp = BatchSpanProcessor.new(exporter: te, max_queue_size: 6, max_export_batch_size: 3)

      tss = [TestSpan.new, TestSpan.new, TestSpan.new, TestSpan.new]
      tss.each { |ts| bsp.on_finish(ts) }
      bsp.shutdown

      _(te.batches[0].size).must_equal(3)
      _(te.batches[1].size).must_equal(1)
    end

    it 'should batch only recording samples' do
      te = TestExporter.new

      bsp = BatchSpanProcessor.new(exporter: te, max_queue_size: 6, max_export_batch_size: 3)

      tss = [TestSpan.new, TestSpan.new(nil, false)]
      tss.each { |ts| bsp.on_finish(ts) }
      bsp.shutdown

      _(te.batches[0].size).must_equal(1)
    end
  end

  describe 'export retry' do
    it 'should not retry on FAILURE exports' do
      te = TestExporter.new(status_codes: [FAILURE, SUCCESS])

      bsp = BatchSpanProcessor.new(schedule_delay_millis: 999,
                                   exporter: te,
                                   max_queue_size: 6,
                                   max_export_batch_size: 3)

      tss = [TestSpan.new, TestSpan.new, TestSpan.new, TestSpan.new]
      tss.each { |ts| bsp.on_finish(ts) }

      # Ensure that our work thread has time to loop
      sleep(1)
      bsp.shutdown

      _(te.batches.size).must_equal(1)
      _(te.batches[0].size).must_equal(1)

      _(te.failed_batches.size).must_equal(1)
      _(te.failed_batches[0].size).must_equal(3)
    end
  end

  describe 'stress test' do
    it 'shouldnt blow up with a lot of things' do
      te = TestExporter.new

      bsp = BatchSpanProcessor.new(exporter: te)
      producers = 10.times.map do |i|
        Thread.new do
          x = i * 10
          10.times do |j|
            bsp.on_finish(TestSpan.new(x + j))
          end
          sleep(rand(0.01))
        end
      end
      producers.each(&:join)
      bsp.shutdown

      out = te.batches.flatten.map(&:id).sort

      expected = 100.times.map { |i| i }

      _(out).must_equal(expected)
    end
  end

  describe 'export timeout' do
    let(:exporter) do
      TestTimeoutExporter.new(status_codes: [SUCCESS],
                              sleep_for_millis: exporter_sleeps_for_millis)
    end
    let(:processor) do
      BatchSpanProcessor.new(exporter: exporter,
                             exporter_timeout_millis: exporter_timeout_millis,
                             schedule_delay_millis: schedule_delay_millis)
    end
    let(:schedule_delay_millis) { 50 }
    let(:exporter_timeout_millis) { 100 }
    let(:spans) { [TestSpan.new, TestSpan.new] }

    before do
      spans.each { |ts| processor.on_finish(ts) }

      # Ensure that work thread loops (longer than 'schedule_delay_millis'):
      sleep((schedule_delay_millis + 100) / 1000.0)
      processor.shutdown
    end

    describe 'normally' do
      let(:exporter_sleeps_for_millis) { exporter_timeout_millis - 1 }

      it 'exporter is not interrupted' do
        _(exporter.state).must_equal(:not_interrupted)
      end
    end

    describe 'when exporter runs too long' do
      let(:exporter_sleeps_for_millis) { exporter_timeout_millis + 700 }

      it 'is interrupted by a timeout' do
        _(exporter.state).must_equal(:called)
      end
    end
  end

  describe 'fork safety test' do
    let(:exporter) { TestExporter.new }
    let(:bsp) do
      BatchSpanProcessor.new(exporter: exporter,
                             max_queue_size: 10,
                             max_export_batch_size: 3)
    end

    describe 'when a process fork occurs' do
      it 'creates new work thread' do
        parent_pid = bsp.instance_variable_get(:@pid)
        parent_work_thread_id = bsp.instance_variable_get(:@thread).object_id
        Process.stub(:pid, parent_pid + rand(1..10)) do
          # Start a new span on the forked process and export it.
          bsp.on_finish(TestSpan.new)
          bsp.shutdown
          current_pid = bsp.instance_variable_get(:@pid)
          current_work_thread_id = bsp.instance_variable_get(:@thread).object_id
          _(parent_pid).wont_equal current_pid
          _(parent_work_thread_id).wont_equal current_work_thread_id
        end
      end
    end
  end
end
