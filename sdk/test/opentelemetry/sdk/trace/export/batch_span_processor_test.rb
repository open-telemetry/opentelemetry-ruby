# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor do
  BatchSpanProcessor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor

  class TestExporter
    def export(batch)
      batches << batch
    end

    def batches
      @batches ||= []
    end
  end

  class TestSpan
    def initialize(id = nil, recording_events = true)
      @id = id
      @recording_events = recording_events
    end

    attr_reader :id

    def recording_events?
      @recording_events
    end

    def to_span_data
      self
    end
  end

  describe 'lifecycle' do
    it 'should stop and start correctly' do
      bsp = BatchSpanProcessor.new(exporter: TestExporter.new)
      bsp.shutdown
    end

    it 'should flush everything on shutdown' do
      te = TestExporter.new
      bsp = BatchSpanProcessor.new(exporter: te, max_queue_size: 3)
      ts = TestSpan.new
      bsp.on_end(ts)

      bsp.shutdown

      te.batches.must_equal [[ts]]
    end
  end

  describe 'batching' do
    it 'should batch up to but not over the max_batch' do
      te = TestExporter.new

      bsp = BatchSpanProcessor.new(exporter: te, max_queue_size: 6, max_export_batch_size: 3)

      tss = [TestSpan.new, TestSpan.new, TestSpan.new, TestSpan.new]
      tss.each { |ts| bsp.on_end(ts) }
      bsp.shutdown

      te.batches[0].size.must_equal(3)
      te.batches[1].size.must_equal(1)
    end

    it 'should batch only recording_events samples' do
      te = TestExporter.new

      bsp = BatchSpanProcessor.new(exporter: te, max_queue_size: 6, max_export_batch_size: 3)

      tss = [TestSpan.new, TestSpan.new(nil, false)]
      tss.each { |ts| bsp.on_end(ts) }
      bsp.shutdown

      te.batches[0].size.must_equal(1)
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
            bsp.on_end(TestSpan.new(x + j))
          end
          sleep(rand(0.01))
        end
      end
      producers.each(&:join)
      bsp.shutdown

      out = te.batches.flatten.map(&:id).sort

      expected = 100.times.map { |i| i }

      out.must_equal(expected)
    end
  end
end
