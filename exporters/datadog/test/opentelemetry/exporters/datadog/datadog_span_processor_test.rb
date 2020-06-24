# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'
require 'faux_writer_helper'

# Give access to otherwise private members
module OpenTelemetry
  module Exporters
    module Datadog
      class Exporter
        attr_accessor :agent_writer, :agent_url, :service
      end
    end
  end
end

# An invalid trace identifier, a 16-byte array with all zero bytes, encoded
# as a hexadecimal string.
INVALID_TRACE_ID = ('0' * 32).freeze

describe OpenTelemetry::Exporters::Datadog::DatadogSpanProcessor do
  DatadogSpanProcessor = OpenTelemetry::Exporters::Datadog::DatadogSpanProcessor
  SUCCESS = begin
              OpenTelemetry::SDK::Trace::Export::SUCCESS
            rescue NameError
              0
            end
  FAILURE = begin
              OpenTelemetry::SDK::Trace::Export::FAILURE
            rescue NameError
              1
            end

  class TestExporter
    def initialize(status_codes: nil)
      @status_codes = status_codes || []
      @traces = []
      @failed_traces = []
      @shutdown_flag = false
    end

    attr_reader :traces
    attr_reader :failed_traces
    attr_reader :shutdown_flag

    def export(batch)
      # If status codes is empty, its a success for less verbose testing
      s = @status_codes.shift
      if s.nil? || s == SUCCESS
        @traces << batch
        SUCCESS
      else
        @failed_traces << batch
        s
      end
    end

    def shutdown
      @shutdown_flag = true
    end
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
    def initialize(id = nil, recording = true, trace_id = nil)
      trace_flags = recording ? OpenTelemetry::Trace::TraceFlags::SAMPLED : OpenTelemetry::Trace::TraceFlags::DEFAULT
      @context = if trace_id
                   OpenTelemetry::Trace::SpanContext.new(trace_flags: trace_flags, trace_id: trace_id)
                 else
                   OpenTelemetry::Trace::SpanContext.new(trace_flags: trace_flags)
                 end
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
    it 'if max trace size is gt max queue size raise' do
      assert_raises ArgumentError do
        DatadogSpanProcessor.new(exporter: TestExporter.new, max_queue_size: 6, max_trace_size: 999)
      end
    end
  end

  describe 'lifecycle' do
    it 'should stop and start correctly' do
      te = TestExporter.new
      dsp = DatadogSpanProcessor.new(exporter: te)
      dsp.shutdown

      _(te.shutdown_flag).must_equal(true)
    end

    it 'should flush everything on shutdown' do
      te = TestExporter.new
      dsp = DatadogSpanProcessor.new(exporter: te)
      ts = TestSpan.new
      dsp.on_start(ts)
      dsp.on_finish(ts)

      dsp.shutdown

      _(te.traces).must_equal [[ts]]
    end
  end

  describe 'batching' do
    it 'should batch up to but not over the max_queue_size' do
      te = TestExporter.new

      dsp = DatadogSpanProcessor.new(exporter: te, max_queue_size: 3, max_trace_size: 3)

      tss = [TestSpan.new, TestSpan.new, TestSpan.new, TestSpan.new]
      tss.each do |ts|
        dsp.on_start(ts)
        dsp.on_finish(ts)
      end
      dsp.shutdown

      _(te.traces.size).must_equal(3)
      _(te.traces[0].size).must_equal(1)
    end

    it 'should drop spans above max_trace_size' do
      te = TestExporter.new

      dsp = DatadogSpanProcessor.new(exporter: te, max_queue_size: 4, max_trace_size: 2)

      trace_id = generate_trace_id
      spans = [TestSpan.new(1, true, trace_id), TestSpan.new(2, true, trace_id), TestSpan.new(3, true, trace_id)]

      spans.each do |span|
        dsp.on_start(span)
      end

      spans.each do |span|
        dsp.on_finish(span)
      end

      dsp.shutdown

      _(te.traces.size).must_equal(1)
      _(te.traces[0].size).must_equal(2)
    end

    it 'should batch all samples' do
      te = TestExporter.new

      dsp = DatadogSpanProcessor.new(exporter: te)

      tss = [TestSpan.new, TestSpan.new(nil, false)]
      tss.each do |ts|
        dsp.on_start(ts)
        dsp.on_finish(ts)
      end
      dsp.shutdown

      _(te.traces.size).must_equal(2)
    end
  end

  describe 'stress test' do
    it 'shouldnt drop traces below max_queue_size' do
      te = TestExporter.new

      dsp = DatadogSpanProcessor.new(exporter: te)
      producers = 10.times.map do |i|
        Thread.new do
          100.times do |j|
            span = TestSpan.new(j + (i * 100))
            dsp.on_start(span)
            dsp.on_finish(span)
          end
          sleep(rand(0.01))
        end
      end
      producers.each(&:join)
      dsp.shutdown

      out = te.traces.flatten.map(&:id).sort

      expected = 1000.times.map { |i| i }

      _(out).must_equal(expected)
    end

    it 'shouldnt blow up with a lot of large traces' do
    end
  end

  describe 'scheduled delay' do
    it 'should flush after scheduled delay' do
      te = TestExporter.new

      dsp = DatadogSpanProcessor.new(exporter: te, max_queue_size: 3, max_trace_size: 3, schedule_delay_millis: 500)

      tss = [TestSpan.new, TestSpan.new, TestSpan.new]
      tss.each do |ts|
        dsp.on_start(ts)
        dsp.on_finish(ts)
      end
      sleep 0.75

      _(te.traces.size).must_equal(3)
      _(te.traces[0].size).must_equal(1)
      dsp.shutdown
    end
  end

  describe 'scheduled delay' do
    it 'should not flush earlier than scheduled delay' do
      te = TestExporter.new

      dsp = DatadogSpanProcessor.new(exporter: te, max_queue_size: 3, max_trace_size: 3, schedule_delay_millis: 1000)

      tss = [TestSpan.new, TestSpan.new, TestSpan.new]
      tss.each do |ts|
        dsp.on_start(ts)
        dsp.on_finish(ts)
      end
      sleep 0.5

      _(te.traces.size).must_equal(0)
      dsp.shutdown
    end
  end

  describe 'force flush' do
    it 'should flush only finished traces' do
      te = TestExporter.new

      dsp = DatadogSpanProcessor.new(exporter: te, max_queue_size: 4, max_trace_size: 3)

      trace_id = generate_trace_id
      spans = [TestSpan.new(1, true, trace_id), TestSpan.new, TestSpan.new, TestSpan.new(4, true, trace_id)]

      4.times do |count|
        dsp.on_start(spans[count])
      end

      3.times do |count|
        dsp.on_finish(spans[count])
      end

      dsp.force_flush

      _(te.traces.size).must_equal(2)
      dsp.shutdown
    end
  end

  def generate_trace_id
    loop do
      id = Random::DEFAULT.bytes(16).unpack1('H*')
      return id unless id == INVALID_TRACE_ID
    end
  end
end
