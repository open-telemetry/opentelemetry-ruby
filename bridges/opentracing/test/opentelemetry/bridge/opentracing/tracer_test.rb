# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::Tracer do
  SpanContext = OpenTelemetry::Trace::SpanContext
  SpanContextBridge = OpenTelemetry::Bridge::OpenTracing::SpanContext
  let(:tracer_bridge) { OpenTelemetry::Bridge::OpenTracing::Tracer.new }
  describe '#active_span' do
    it 'gets the tracers active span' do
    end
  end

  describe '#start_span' do
    it 'calls start span on the tracer' do
    end

    it 'calls with_span if a block is given, yielding the span and returning the blocks value' do
    end

    it 'returns the span' do
    end
  end

  describe '#start_active_span' do
    it 'calls start span on the tracer and with_span to make active' do
    end

    it 'calls with_span if a block is given, yielding the scope and returning the blocks value' do
    end

    it 'returns a scope' do
    end
  end

  describe '#inject' do
    it 'injects TEXT_MAP format as HTTP_TEXT_FORMAT' do
    end

    it 'injects RACK format as HTTP_TEXT_FORMAT' do
    end

    it 'injects binary format onto the context' do
    end
  end

  describe '#extract' do
    it 'extracts HTTP format from the context' do
    end

    it 'extracts rack format from the context' do
    end

    it 'extracts binary format from the context' do
    end
  end
end
