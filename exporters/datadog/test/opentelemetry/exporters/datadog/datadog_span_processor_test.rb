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


describe OpenTelemetry::Exporters::Datadog::DatadogSpanProcessor do
  DatadogSpanProcessor = OpenTelemetry::Exporters::Datadog::DatadogSpanProcessor
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILED_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_RETRYABLE
  FAILED_NOT_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_NOT_RETRYABLE

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
        DatadogSpanProcessor.new(exporter: TestExporter.new, max_queue_size: 6, max_export_batch_size: 999)
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

      dsp = DatadogSpanProcessor.new(exporter: te, max_queue_size: 3, max_export_batch_size: 3 )

      tss = [TestSpan.new, TestSpan.new, TestSpan.new, TestSpan.new]
      tss.each do |ts| 
        dsp.on_start(ts)
        dsp.on_finish(ts)
      end
      dsp.shutdown

      _(te.traces.size).must_equal(3)
      _(te.traces[0].size).must_equal(1)
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
end